-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010012-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010015-SQLite.sql':

BEGIN;

CREATE TABLE queue (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  producer VARCHAR(255) DEFAULT '',
  priority INT(10) NOT NULL DEFAULT '0',
  runcount INT(10) NOT NULL DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);


CREATE TABLE testrun_requested_feature (
  id INT NOT NULL,
  testrun_id INTEGER PRIMARY KEY NOT NULL,
  feature VARCHAR(255) DEFAULT ''
);

CREATE INDEX testrun_requested_feature_idx_testrun_id_testrun_reques_ ON testrun_requested_feature (testrun_id);

CREATE TABLE testrun_scheduling (
  id INT NOT NULL,
  testrun_id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) DEFAULT '0',
  built INT(1) DEFAULT '0',
  active INT(1) DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

CREATE INDEX testrun_scheduling_idx_queue_id_testrun_scheduli_ ON testrun_scheduling (queue_id);
CREATE INDEX testrun_scheduling_idx_testrun_id_testrun_schedu_ ON testrun_scheduling (testrun_id);





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
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);
CREATE INDEX testrun_idx_owner_user_id_test_testru ON testrun (owner_user_id);
CREATE INDEX testrun_idx_topic_name_testrun_testru ON testrun (topic_name);
INSERT INTO testrun SELECT id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, hardwaredb_systems_id, owner_user_id, test_program, wait_after_tests, created_at, updated_at FROM testrun_temp_alter;
DROP TABLE testrun_temp_alter;







COMMIT;
