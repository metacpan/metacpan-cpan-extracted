-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010011-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010012':

BEGIN;

ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;

COMMIT;
