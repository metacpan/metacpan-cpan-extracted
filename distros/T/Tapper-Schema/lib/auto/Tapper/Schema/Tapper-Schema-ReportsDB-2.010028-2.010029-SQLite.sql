-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010028-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010029-SQLite.sql':;

BEGIN;

DROP INDEX reportgrouptestrunstats_idx_testrun_id;

ALTER TABLE reportgrouptestrunstats ADD COLUMN success_ratio VARCHAR(20);


COMMIT;

