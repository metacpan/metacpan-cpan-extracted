-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000002-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000004-SQLite.sql':;

BEGIN;

ALTER TABLE reportgrouparbitrary ADD COLUMN owner VARCHAR(255);

ALTER TABLE reportgrouptestrun ADD COLUMN owner VARCHAR(255);


COMMIT;

