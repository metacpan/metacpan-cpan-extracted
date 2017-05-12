-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010028-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010029':;

BEGIN;

ALTER TABLE reportgrouptestrunstats ADD COLUMN success_ratio VARCHAR(20);


COMMIT;

