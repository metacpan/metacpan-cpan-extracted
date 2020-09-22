# $Id: create.sql,v 1.4 2008-06-06 14:28:35 mike Exp $

SET NAMES utf8;
SET CHARSET utf8;
SET character_set_database=utf8;

drop database if exists books;
create database books;
use books;

GRANT ALL PRIVILEGES ON books.* TO ""@"localhost";

CREATE TABLE country(id INT, name TEXT);
CREATE TABLE author(id INT, name TEXT, country_id INT,
	fulltext index (name)) ENGINE = MYISAM;
CREATE TABLE book(id INT, author_id INT, name TEXT, year INT, notes TEXT,
	fulltext index (name)) ENGINE = MYISAM;

