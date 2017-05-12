-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010031-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010032':;

BEGIN;

ALTER TABLE host ADD COLUMN comment VARCHAR(255) DEFAULT '';

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

