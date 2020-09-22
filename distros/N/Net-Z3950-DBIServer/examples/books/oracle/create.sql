# $Id: create.sql,v 1.2 2008-05-16 15:54:41 mike Exp $

DROP TABLE country;
DROP TABLE author;
DROP TABLE book;
CREATE TABLE country(id INT, name VARCHAR(255));
CREATE TABLE author(id INT, name VARCHAR(255), country_id INT);
CREATE TABLE book(id INT, author_id INT, name VARCHAR(255), year INT, notes VARCHAR(255));

