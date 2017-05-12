-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010034-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010035-SQLite.sql':;

BEGIN;

CREATE TABLE testplan_instance (
  id INTEGER PRIMARY KEY NOT NULL,
  path VARCHAR(255) DEFAULT '',
  evaluated_testplan TEXT DEFAULT '',
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);

ALTER TABLE testrun ADD COLUMN testplan_id INT(11);

CREATE INDEX testrun_idx_testplan_id02 ON testrun (testplan_id);


COMMIT;

