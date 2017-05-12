-- Convert schema '/home/mhentsc3/perl510/lib/site_perl/5.10.0/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000001-SQLite.sql' to '/home/mhentsc3/perl510/lib/site_perl/5.10.0/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000002-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE message_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11),
  message VARCHAR(65000),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

INSERT INTO message_temp_alter SELECT id, testrun_id, message, type, created_at, updated_at FROM message;

DROP TABLE message;

CREATE TABLE message (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11),
  message VARCHAR(65000),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

CREATE INDEX message_idx_testrun_id03 ON message (testrun_id);

INSERT INTO message SELECT id, testrun_id, message, type, created_at, updated_at FROM message_temp_alter;

DROP TABLE message_temp_alter;


COMMIT;

