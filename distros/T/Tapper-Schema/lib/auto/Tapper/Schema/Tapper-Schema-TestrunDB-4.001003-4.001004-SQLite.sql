-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001003-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001004-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE preconditiontype_temp_alter (
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);

INSERT INTO preconditiontype_temp_alter( name, description) SELECT name, description FROM preconditiontype;

DROP TABLE preconditiontype;

CREATE TABLE preconditiontype (
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);

INSERT INTO preconditiontype SELECT name, description FROM preconditiontype_temp_alter;

DROP TABLE preconditiontype_temp_alter;

CREATE INDEX testrun_idx_created_at02 ON testrun (created_at);

CREATE INDEX testrun_scheduling_idx_crea00 ON testrun_scheduling (created_at);


COMMIT;

