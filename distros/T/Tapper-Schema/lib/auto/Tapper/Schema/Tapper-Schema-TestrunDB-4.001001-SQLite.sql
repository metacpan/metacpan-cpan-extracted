-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Aug 14 11:48:55 2012
-- 

BEGIN TRANSACTION;

--
-- Table: owner
--
DROP TABLE owner;

CREATE TABLE owner (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255),
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);

--
-- Table: host
--
DROP TABLE host;

CREATE TABLE host (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  comment VARCHAR(255) DEFAULT '',
  free TINYINT DEFAULT 0,
  active TINYINT DEFAULT 0,
  is_deleted TINYINT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
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
-- Table: queue
--
DROP TABLE queue;

CREATE TABLE queue (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  priority INT(10) NOT NULL DEFAULT 0,
  runcount INT(10) NOT NULL DEFAULT 0,
  active INT(1) DEFAULT 0,
  is_deleted TINYINT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

CREATE UNIQUE INDEX unique_queue_name ON queue (name);

--
-- Table: scenario
--
DROP TABLE scenario;

CREATE TABLE scenario (
  id INTEGER PRIMARY KEY NOT NULL,
  type VARCHAR(255) NOT NULL DEFAULT ''
);

--
-- Table: testplan_instance
--
DROP TABLE testplan_instance;

CREATE TABLE testplan_instance (
  id INTEGER PRIMARY KEY NOT NULL,
  path VARCHAR(255) DEFAULT '',
  name VARCHAR(255) DEFAULT '',
  evaluated_testplan TEXT DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

--
-- Table: topic
--
DROP TABLE topic;

CREATE TABLE topic (
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);

--
-- Table: host_feature
--
DROP TABLE host_feature;

CREATE TABLE host_feature (
  id INTEGER PRIMARY KEY NOT NULL,
  host_id INT NOT NULL,
  entry VARCHAR(255) NOT NULL,
  value VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX host_feature_idx_host_id ON host_feature (host_id);

--
-- Table: pre_precondition
--
DROP TABLE pre_precondition;

CREATE TABLE pre_precondition (
  parent_precondition_id INT(11) NOT NULL,
  child_precondition_id INT(11) NOT NULL,
  succession INT(10) NOT NULL,
  PRIMARY KEY (parent_precondition_id, child_precondition_id),
  FOREIGN KEY (child_precondition_id) REFERENCES precondition(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (parent_precondition_id) REFERENCES precondition(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX pre_precondition_idx_child_precondition_id ON pre_precondition (child_precondition_id);

CREATE INDEX pre_precondition_idx_parent_precondition_id ON pre_precondition (parent_precondition_id);

--
-- Table: queue_host
--
DROP TABLE queue_host;

CREATE TABLE queue_host (
  id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (queue_id) REFERENCES queue(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX queue_host_idx_host_id ON queue_host (host_id);

CREATE INDEX queue_host_idx_queue_id ON queue_host (queue_id);

--
-- Table: testrun
--
DROP TABLE testrun;

CREATE TABLE testrun (
  id INTEGER PRIMARY KEY NOT NULL,
  shortname VARCHAR(255) DEFAULT '',
  notes TEXT DEFAULT '',
  topic_name VARCHAR(255) NOT NULL DEFAULT '',
  starttime_earliest DATETIME,
  starttime_testrun DATETIME,
  starttime_test_program DATETIME,
  endtime_test_program DATETIME,
  owner_id INT(11),
  testplan_id INT(11),
  wait_after_tests INT(1) DEFAULT 0,
  rerun_on_error INT(11) DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES owner(id),
  FOREIGN KEY (testplan_id) REFERENCES testplan_instance(id) ON UPDATE CASCADE
);

CREATE INDEX testrun_idx_owner_id ON testrun (owner_id);

CREATE INDEX testrun_idx_testplan_id ON testrun (testplan_id);

--
-- Table: message
--
DROP TABLE message;

CREATE TABLE message (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11),
  message VARCHAR(65000),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX message_idx_testrun_id ON message (testrun_id);

--
-- Table: state
--
DROP TABLE state;

CREATE TABLE state (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  state VARCHAR(65000),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE
);

CREATE INDEX state_idx_testrun_id ON state (testrun_id);

CREATE UNIQUE INDEX unique_testrun_id ON state (testrun_id);

--
-- Table: testrun_requested_feature
--
DROP TABLE testrun_requested_feature;

CREATE TABLE testrun_requested_feature (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  feature VARCHAR(255) DEFAULT '',
  FOREIGN KEY (testrun_id) REFERENCES testrun(id)
);

CREATE INDEX testrun_requested_feature_idx_testrun_id ON testrun_requested_feature (testrun_id);

--
-- Table: scenario_element
--
DROP TABLE scenario_element;

CREATE TABLE scenario_element (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  scenario_id INT(11) NOT NULL,
  is_fitted INT(1) NOT NULL DEFAULT 0,
  FOREIGN KEY (scenario_id) REFERENCES scenario(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE
);

CREATE INDEX scenario_element_idx_scenario_id ON scenario_element (scenario_id);

CREATE INDEX scenario_element_idx_testrun_id ON scenario_element (testrun_id);

--
-- Table: testrun_precondition
--
DROP TABLE testrun_precondition;

CREATE TABLE testrun_precondition (
  testrun_id INT(11) NOT NULL,
  precondition_id INT(11) NOT NULL,
  succession INT(10),
  PRIMARY KEY (testrun_id, precondition_id),
  FOREIGN KEY (precondition_id) REFERENCES precondition(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX testrun_precondition_idx_precondition_id ON testrun_precondition (precondition_id);

CREATE INDEX testrun_precondition_idx_testrun_id ON testrun_precondition (testrun_id);

--
-- Table: testrun_requested_host
--
DROP TABLE testrun_requested_host;

CREATE TABLE testrun_requested_host (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY (host_id) REFERENCES host(id),
  FOREIGN KEY (testrun_id) REFERENCES testrun(id)
);

CREATE INDEX testrun_requested_host_idx_host_id ON testrun_requested_host (host_id);

CREATE INDEX testrun_requested_host_idx_testrun_id ON testrun_requested_host (testrun_id);

--
-- Table: testrun_scheduling
--
DROP TABLE testrun_scheduling;

CREATE TABLE testrun_scheduling (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  queue_id INT(11) DEFAULT 0,
  host_id INT(11),
  prioqueue_seq INT(11),
  status VARCHAR(255) DEFAULT 'prepare',
  auto_rerun TINYINT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (queue_id) REFERENCES queue(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE
);

CREATE INDEX testrun_scheduling_idx_host_id ON testrun_scheduling (host_id);

CREATE INDEX testrun_scheduling_idx_queue_id ON testrun_scheduling (queue_id);

CREATE INDEX testrun_scheduling_idx_testrun_id ON testrun_scheduling (testrun_id);

COMMIT;
