-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon Aug 31 11:21:37 2009
-- 


BEGIN TRANSACTION;

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
-- Table: testrun_scheduling
--
DROP TABLE queue;

CREATE TABLE queue (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  producer VARCHAR(255) DEFAULT '',
  priority INT(10) NOT NULL DEFAULT '0',
  runcount INT(10) NOT NULL DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
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

CREATE INDEX pre_precondition_idx_child_precondition_id_pre ON pre_precondition (child_precondition_id);

CREATE INDEX pre_precondition_idx_parent_precondition_id_pr ON pre_precondition (parent_precondition_id);

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
  wait_after_tests INT(1) DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

CREATE INDEX testrun_idx_owner_user_id_test ON testrun (owner_user_id);

CREATE INDEX testrun_idx_topic_name_testrun ON testrun (topic_name);

--
-- Table: testrun_requested_feature
--
DROP TABLE testrun_requested_feature;

CREATE TABLE testrun_requested_feature (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  feature VARCHAR(255) DEFAULT ''
);

CREATE INDEX testrun_idx_topic_name ON testrun (topic_name);

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

CREATE INDEX testrun_precondition_idx_precondition_id_testrun_p ON testrun_precondition (precondition_id);

CREATE INDEX testrun_precondition_idx_testrun_id_testrun_precon ON testrun_precondition (testrun_id);

--
-- Table: testrun_scheduling
--
DROP TABLE testrun_scheduling;

CREATE TABLE testrun_scheduling (
  id INT NOT NULL,
  testrun_id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) DEFAULT '0',
  built INT(1) DEFAULT '0',
  active INT(1) DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

CREATE INDEX testrun_scheduling_idx_queue_id_testrun_scheduli ON testrun_scheduling (queue_id);

CREATE INDEX testrun_scheduling_idx_testrun_id_testrun_schedu ON testrun_scheduling (testrun_id);

--
-- Table: host
--
--DROP TABLE host;
--
--CREATE TABLE host (
--  id INTEGER PRIMARY KEY NOT NULL,
--  name VARCHAR(255) DEFAULT '',
--  allowed_context VARCHAR(255) DEFAULT '',
--  busy VARCHAR(255) DEFAULT '',
--  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--  updated_at DATETIME
--);

COMMIT;
