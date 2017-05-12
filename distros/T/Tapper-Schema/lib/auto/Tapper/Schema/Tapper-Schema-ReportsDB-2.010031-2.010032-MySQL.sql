-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010031-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010032':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN kernel VARCHAR(255);


COMMIT;

