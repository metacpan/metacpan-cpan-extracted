-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010024-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010028-SQLite.sql':;

BEGIN;

ALTER TABLE queue ADD COLUMN active INT(1) DEFAULT '0';

CREATE TEMPORARY TABLE testrun_temp_alter (
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
  wait_after_tests INT(1) DEFAULT '0',
  rerun_on_error INT(11) DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

INSERT INTO testrun_temp_alter SELECT id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, hardwaredb_systems_id, owner_user_id, wait_after_tests, rerun_on_error, created_at, updated_at FROM testrun;

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
  wait_after_tests INT(1) DEFAULT '0',
  rerun_on_error INT(11) DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

CREATE INDEX testrun_idx_owner_user_id03 ON testrun (owner_user_id);

INSERT INTO testrun SELECT id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, hardwaredb_systems_id, owner_user_id, wait_after_tests, rerun_on_error, created_at, updated_at FROM testrun_temp_alter;

DROP TABLE testrun_temp_alter;


COMMIT;

