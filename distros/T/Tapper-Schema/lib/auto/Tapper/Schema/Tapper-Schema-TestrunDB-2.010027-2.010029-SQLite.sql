-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010027-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010029-SQLite.sql':;

BEGIN;

ALTER TABLE queue ADD COLUMN active INT(1) DEFAULT '0';

CREATE TEMPORARY TABLE testrun_scheduling_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  queue_id INT(11) DEFAULT '0',
  host_id INT(11),
  prioqueue_seq INT(11),
  status VARCHAR(255) DEFAULT 'prepare',
  auto_rerun TINYINT DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

INSERT INTO testrun_scheduling_temp_alter SELECT id, testrun_id, queue_id, host_id, prioqueue_seq, status, auto_rerun, created_at, updated_at FROM testrun_scheduling;

DROP TABLE testrun_scheduling;

CREATE TABLE testrun_scheduling (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  queue_id INT(11) DEFAULT '0',
  host_id INT(11),
  prioqueue_seq INT(11),
  status VARCHAR(255) DEFAULT 'prepare',
  auto_rerun TINYINT DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

CREATE INDEX testrun_scheduling_idx_host00 ON testrun_scheduling (host_id);

CREATE INDEX testrun_scheduling_idx_queu00 ON testrun_scheduling (queue_id);

CREATE INDEX testrun_scheduling_idx_test00 ON testrun_scheduling (testrun_id);

INSERT INTO testrun_scheduling SELECT id, testrun_id, queue_id, host_id, prioqueue_seq, status, auto_rerun, created_at, updated_at FROM testrun_scheduling_temp_alter;

DROP TABLE testrun_scheduling_temp_alter;


COMMIT;

