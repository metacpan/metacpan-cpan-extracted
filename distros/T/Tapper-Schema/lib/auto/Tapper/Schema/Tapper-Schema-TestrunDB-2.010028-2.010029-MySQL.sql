-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010028-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010029':;

BEGIN;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

