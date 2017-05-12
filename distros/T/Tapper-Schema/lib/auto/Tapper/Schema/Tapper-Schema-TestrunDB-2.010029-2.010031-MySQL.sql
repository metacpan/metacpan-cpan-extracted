-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010029-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010031':;

BEGIN;

ALTER TABLE testrun CHANGE COLUMN topic_name topic_name VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';

ALTER TABLE topic CHANGE COLUMN name name VARCHAR(255) NOT NULL;


COMMIT;

