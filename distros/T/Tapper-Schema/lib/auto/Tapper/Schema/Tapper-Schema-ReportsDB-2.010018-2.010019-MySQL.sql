-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010018-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010019':

BEGIN;

ALTER TABLE report ADD COLUMN tapdata LONGBLOB NOT NULL DEFAULT '',
                   CHANGE COLUMN tap tap LONGBLOB NOT NULL DEFAULT '';
ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;

COMMIT;
