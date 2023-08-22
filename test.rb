require "sqlite3"
require 'pry'


def init_db(db)
  # This entire function just resets the database
  # Drop existing tables
  db.execute "drop table names"
  db.execute "drop table words"

  # Create empty names table
  db.execute <<-SQL
    create table names (
      text varchar(50)
    );
  SQL

  # Create empty words table
  db.execute <<-SQL
    create table words (
      text varchar(50)
    );
  SQL
end

def parse_alphabetic_characters(word)
  # Only returns characters between the a-z and A-Z ascii values.  See a list here: https://www.asciitable.com/
  # This do block basically takes something like "Title:" and converts it into ['T', 'i', 't', 'l', 'e']
  # Note how it removes colon (:) character
  alphabetic_characters = word.split('').select do |character|
    next true if character.ord.between?('a'.ord,'z'.ord)
    next true if character.ord.between?('A'.ord,'Z'.ord)

    false
  end

  # The above statement comes back as an array, so we need to join the characters and convert them to lowercase
  # Ex: ['T', 'i', 't', 'l', 'e'] becomes "title"
  alphabetic_characters.join.downcase
end

def fill_names_table_data(db)
  # Reads the lines of the names-dataset file, removes any whitespace/newline characters and adds it to the database
  # Ex: "   noah \n" becomes "noah"
  File.readlines('names-dataset.txt').each do |name|
    db.execute("insert into names values (?)", name.strip)
  end
end

def fill_words_table_data(db)
  # Same thing as fill_names_table_data
  # We're calling one extra function here to remove all characters from the word that are not in the alphabet
  # You can read more about it in the parse_alphabetic_characters function
  File.readlines('input.txt').each do |line|
    line.split(' ').each do |word|
      formatted_word = parse_alphabetic_characters(word.strip)

      db.execute("insert into words values (?)", formatted_word) unless formatted_word.empty?
    end
  end
end

def print_matching(db)
  # This performs an 'INNER JOIN' on the 'names' and 'words' database tables using their 'text' columns
  # All an 'INNER JOIN' does is find rows in the database that match on that column
  # So this will only contain words that match between 'input.txt' and 'names-dataset.txt'
  # Read more about 'JOINS' and play around with an actual database here: https://sqlbolt.com/
  result = db.execute(<<-SQL
    select names.text, count(*) from names
    join words on names.text = words.text
    group by 1
    order by 2 desc
  SQL
  )

  result.each do |match|
    puts "#{match[0]} #{match[1]}"
  end
end

db = SQLite3::Database.new "name.db"
init_db(db)
fill_names_table_data(db)
fill_words_table_data(db)
print_matching(db)