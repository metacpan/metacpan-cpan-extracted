-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon Jun 30 11:13:24 2008
-- 
BEGIN TRANSACTION;


--
-- Table: pre_precondition
--
DROP TABLE pre_precondition;
CREATE TABLE pre_precondition (
  parent_precondition_id INT(11) NOT NULL,
  child_precondition_id INT(11) NOT NULL,
  succession INT(10) NOT NULL,
  PRIMARY KEY (parent_precondition_id, child_precondition_id)
);


--
-- Table: precondition
--
DROP TABLE precondition;
CREATE TABLE precondition (
  id INTEGER PRIMARY KEY NOT NULL,
  shortname VARCHAR(255) NOT NULL DEFAULT '',
  precondition TEXT,
  timeout INT(10)
);


--
-- Table: preconditiontype
--
DROP TABLE preconditiontype;
CREATE TABLE preconditiontype (
  name VARCHAR(20) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);


--
-- Table: testrun
--
DROP TABLE testrun;
CREATE TABLE testrun (
  id INTEGER PRIMARY KEY NOT NULL,
  shortname VARCHAR(255) DEFAULT '',
  notes TEXT DEFAULT '',
  topic_name VARCHAR(20) NOT NULL DEFAULT '',
  starttime_earliest DATETIME,
  starttime_testrun DATETIME,
  starttime_test_program DATETIME,
  endtime_test_program DATETIME,
  hardwaredb_systems_id INT(11),
  owner_user_id INT(11),
  test_program VARCHAR(255) NOT NULL DEFAULT '',
  timeout_after_testprogram INT(10),
  wait_after_tests INT(1) DEFAULT '0',
  created_at DATETIME,
  updated_at DATETIME
);


--
-- Table: testrun_precondition
--
DROP TABLE testrun_precondition;
CREATE TABLE testrun_precondition (
  testrun_id INT(11) NOT NULL,
  precondition_id INT(11) NOT NULL,
  succession INT(10),
  PRIMARY KEY (testrun_id, precondition_id)
);


--
-- Table: topic
--
DROP TABLE topic;
CREATE TABLE topic (
  name VARCHAR(20) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);


--
-- Table: user
--
DROP TABLE user;
CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);


COMMIT;
