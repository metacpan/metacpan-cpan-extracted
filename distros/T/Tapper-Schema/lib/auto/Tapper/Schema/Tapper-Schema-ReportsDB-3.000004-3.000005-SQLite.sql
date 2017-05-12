-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000004-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000005-SQLite.sql':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN moreinfo_url VARCHAR(255);


COMMIT;

