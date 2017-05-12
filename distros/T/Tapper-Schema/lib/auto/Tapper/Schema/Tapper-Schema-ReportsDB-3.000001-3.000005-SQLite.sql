-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000001-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000005-SQLite.sql':;

BEGIN;

ALTER TABLE reportfile ADD COLUMN is_compressed INT NOT NULL DEFAULT 0;

ALTER TABLE reportgrouparbitrary ADD COLUMN owner VARCHAR(255);

ALTER TABLE reportgrouptestrun ADD COLUMN owner VARCHAR(255);

ALTER TABLE reportsection ADD COLUMN moreinfo_url VARCHAR(255);


COMMIT;

