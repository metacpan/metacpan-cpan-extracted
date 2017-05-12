-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010036-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010037-SQLite.sql':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN tags VARCHAR(255);


COMMIT;

