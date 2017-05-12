-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010014-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010015-SQLite.sql':;

BEGIN;

CREATE TABLE queue (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  producer VARCHAR(255) DEFAULT '',
  priority INT(10) NOT NULL DEFAULT '0',
  runcount INT(10) NOT NULL DEFAULT '0',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
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
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

CREATE INDEX testrun_scheduling_idx_queue_id_testrun_scheduli_ ON testrun_scheduling (queue_id);

CREATE INDEX testrun_scheduling_idx_testrun_id_testrun_schedu_ ON testrun_scheduling (testrun_id);


COMMIT;

