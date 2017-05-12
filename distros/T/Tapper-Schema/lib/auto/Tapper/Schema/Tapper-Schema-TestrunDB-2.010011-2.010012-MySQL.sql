-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010011-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010012':;

BEGIN;

ALTER TABLE testrun DROP COLUMN timeout_after_testprogram;


COMMIT;

