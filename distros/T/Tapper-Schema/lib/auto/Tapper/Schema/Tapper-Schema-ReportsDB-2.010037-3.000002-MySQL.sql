-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010037-MySQL.sql' to 'Tapper::Schema::ReportsDB v3.000002':;

BEGIN;

ALTER TABLE reportfile ADD COLUMN is_compressed integer NOT NULL DEFAULT 0;


COMMIT;

