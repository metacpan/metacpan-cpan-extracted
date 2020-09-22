\connect template1
DROP DATABASE books;
CREATE DATABASE books;
\connect books
CREATE TABLE country(id INT, name TEXT);
CREATE TABLE author(id INT, name TEXT, country_id INT);
CREATE TABLE book(id INT, author_id INT, name TEXT, year INT, notes TEXT);
