-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sat Mar 28 17:39:59 2020
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS Datum;

--
-- Table: Datum
--
CREATE TABLE Datum (
  area double NOT NULL DEFAULT 0,
  belongsto varchar(100) NOT NULL,
  confirmed integer NOT NULL DEFAULT 0,
  datasource varchar(100) NOT NULL DEFAULT '<NA>',
  datetimeISO8601 varchar(21) NOT NULL DEFAULT '<NA>',
  datetimeUnixEpoch integer NOT NULL DEFAULT 0,
  id varchar(100) NOT NULL DEFAULT '<NA>',
  name varchar(100) NOT NULL DEFAULT '<NA>',
  population integer NOT NULL DEFAULT 0,
  recovered integer NOT NULL DEFAULT 0,
  terminal integer NOT NULL DEFAULT 0,
  type varchar(100) NOT NULL DEFAULT '<NA>',
  unconfirmed integer NOT NULL DEFAULT 0,
  PRIMARY KEY (id, name, datetimeISO8601)
);

DROP TABLE IF EXISTS Version;

--
-- Table: Version
--
CREATE TABLE Version (
  authoremail varchar(100) NOT NULL DEFAULT 'andreashad2@gmail.com',
  authorname varchar(100) NOT NULL DEFAULT 'Andreas Hadjiprocopis',
  package varchar(100) NOT NULL DEFAULT 'Statistics::Covid',
  version varchar(100) NOT NULL DEFAULT '0.21',
  PRIMARY KEY (version)
);

SET foreign_key_checks=1;

