-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010011-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010012-SQLite.sql':;

BEGIN;

CREATE INDEX pre_precondition_idx_child_precondition_id_pre_ ON pre_precondition (child_precondition_id);

CREATE INDEX pre_precondition_idx_parent_precondition_id_pr_ ON pre_precondition (parent_precondition_id);

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
  test_program VARCHAR(255) NOT NULL DEFAULT '',
  wait_after_tests INT(1) DEFAULT '0',
  created_at DATETIME,
  updated_at DATETIME
);

INSERT INTO testrun_temp_alter SELECT id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, hardwaredb_systems_id, owner_user_id, test_program, wait_after_tests, created_at, updated_at FROM testrun;

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
  created_at DATETIME,
  updated_at DATETIME
);

CREATE INDEX testrun_idx_owner_user_id_test_testru ON testrun (owner_user_id);

CREATE INDEX testrun_idx_topic_name_testrun_testru ON testrun (topic_name);

INSERT INTO testrun SELECT id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, hardwaredb_systems_id, owner_user_id, test_program, wait_after_tests, created_at, updated_at FROM testrun_temp_alter;

DROP TABLE testrun_temp_alter;

CREATE INDEX testrun_precondition_idx_precondition_id_testrun_p_ ON testrun_precondition (precondition_id);

CREATE INDEX testrun_precondition_idx_testrun_id_testrun_precon_ ON testrun_precondition (testrun_id);


COMMIT;

