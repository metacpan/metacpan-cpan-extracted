-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000004-MySQL.sql' to 'Tapper::Schema::ReportsDB v3.000005':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN moreinfo_url VARCHAR(255);


COMMIT;

