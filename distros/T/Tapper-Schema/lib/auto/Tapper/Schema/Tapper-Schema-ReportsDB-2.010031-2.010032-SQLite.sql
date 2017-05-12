-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010031-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010032-SQLite.sql':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN kernel VARCHAR(255);


COMMIT;

