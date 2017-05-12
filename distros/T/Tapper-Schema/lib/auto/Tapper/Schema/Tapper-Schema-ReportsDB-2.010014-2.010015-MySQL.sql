-- Convert schema './Tapper-Schema-ReportsDB-2.010014-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010015':

BEGIN;

ALTER TABLE reportfile CHANGE COLUMN filecontent filecontent LONGBLOB NOT NULL DEFAULT '';
ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;

COMMIT;
