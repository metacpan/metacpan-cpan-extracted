-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010019-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010020-SQLite.sql':;

BEGIN;

CREATE INDEX testrun_idx_topic_name02 ON testrun (topic_name);

CREATE TEMPORARY TABLE testrun_scheduling_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  queue_id INT(11) DEFAULT '0',
  mergedqueue_seq INT(11),
  host_id INT(11),
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
  host_id INT(11),
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

