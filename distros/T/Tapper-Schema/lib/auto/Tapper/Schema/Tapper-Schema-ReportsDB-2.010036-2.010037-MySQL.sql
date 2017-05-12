-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010036-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010037':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN tags VARCHAR(255);


COMMIT;

