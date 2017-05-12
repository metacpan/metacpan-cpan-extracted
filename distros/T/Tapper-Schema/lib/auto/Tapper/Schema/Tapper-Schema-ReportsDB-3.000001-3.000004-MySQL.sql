-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000001-MySQL.sql' to 'Tapper::Schema::ReportsDB v3.000004':;

BEGIN;

ALTER TABLE reportfile ADD COLUMN is_compressed integer NOT NULL DEFAULT 0;

ALTER TABLE reportgrouparbitrary ADD COLUMN owner VARCHAR(255);

ALTER TABLE reportgrouptestrun ADD COLUMN owner VARCHAR(255);


COMMIT;

