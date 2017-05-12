-- Convert schema '/home/hmai/Projekte/Tapper/src/Tapper-Schema/lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000005-SQLite.sql' to '/home/hmai/Projekte/Tapper/src/Tapper-Schema/lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001001-SQLite.sql':;

BEGIN;

CREATE TABLE owner (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255),
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

CREATE TEMPORARY TABLE testrun_temp_alter (
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

INSERT INTO testrun_temp_alter( id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, testplan_id, wait_after_tests, rerun_on_error, created_at, updated_at) SELECT id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, testplan_id, wait_after_tests, rerun_on_error, created_at, updated_at FROM testrun;

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

CREATE INDEX testrun_idx_owner_id03 ON testrun (owner_id);

CREATE INDEX testrun_idx_testplan_id03 ON testrun (testplan_id);

INSERT INTO testrun SELECT id, shortname, notes, topic_name, starttime_earliest, starttime_testrun, starttime_test_program, endtime_test_program, owner_id, testplan_id, wait_after_tests, rerun_on_error, created_at, updated_at FROM testrun_temp_alter;

DROP TABLE testrun_temp_alter;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP TABLE user;


COMMIT;

