-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010037-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-3.000002-SQLite.sql':;

BEGIN;

ALTER TABLE reportfile ADD COLUMN is_compressed INT NOT NULL DEFAULT 0;


COMMIT;

