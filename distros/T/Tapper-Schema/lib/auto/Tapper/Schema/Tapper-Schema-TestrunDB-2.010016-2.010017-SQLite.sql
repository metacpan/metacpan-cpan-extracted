-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010016-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010017-SQLite.sql':;

BEGIN;

CREATE TABLE host (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  free TINYINT DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

CREATE TABLE testrun_requested_host (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  host_id INT
);

CREATE INDEX testrun_requested_host_idx_host_id ON testrun_requested_host (host_id);

CREATE INDEX testrun_requested_host_idx_testrun_id ON testrun_requested_host (testrun_id);

CREATE TEMPORARY TABLE queue_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  priority INT(10) NOT NULL DEFAULT '0',
  runcount INT(10) NOT NULL DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

INSERT INTO queue_temp_alter SELECT id, name, priority, runcount, created_at, updated_at FROM queue;

DROP TABLE queue;

CREATE TABLE queue (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  priority INT(10) NOT NULL DEFAULT '0',
  runcount INT(10) NOT NULL DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

CREATE UNIQUE INDEX unique_queue_name03 ON queue (name);

INSERT INTO queue SELECT id, name, priority, runcount, created_at, updated_at FROM queue_temp_alter;

DROP TABLE queue_temp_alter;

CREATE INDEX testrun_requested_feature_i00 ON testrun_requested_feature (testrun_id);

CREATE TEMPORARY TABLE testrun_scheduling_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  queue_id INT(11) DEFAULT '0',
  mergedqueue_seq INT(11),
  host_id INT(11) DEFAULT '0',
  status VARCHAR(255) DEFAULT 'prepare',
  auto_rerun TINYINT DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

INSERT INTO testrun_scheduling_temp_alter SELECT id, testrun_id, queue_id, mergedqueue_seq, host_id, status, auto_rerun, created_at, updated_at FROM testrun_scheduling;

DROP TABLE testrun_scheduling;

CREATE TABLE testrun_scheduling (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  queue_id INT(11) DEFAULT '0',
  mergedqueue_seq INT(11),
  host_id INT(11) DEFAULT '0',
  status VARCHAR(255) DEFAULT 'prepare',
  auto_rerun TINYINT DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

CREATE INDEX testrun_scheduling_idx_host00 ON testrun_scheduling (host_id);

CREATE INDEX testrun_scheduling_idx_queu00 ON testrun_scheduling (queue_id);

CREATE INDEX testrun_scheduling_idx_test00 ON testrun_scheduling (testrun_id);

INSERT INTO testrun_scheduling SELECT id, testrun_id, queue_id, mergedqueue_seq, host_id, status, auto_rerun, created_at, updated_at FROM testrun_scheduling_temp_alter;

DROP TABLE testrun_scheduling_temp_alter;


COMMIT;

