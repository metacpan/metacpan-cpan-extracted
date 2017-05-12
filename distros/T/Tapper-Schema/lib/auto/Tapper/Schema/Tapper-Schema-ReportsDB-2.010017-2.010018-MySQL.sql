-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010017-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010018':

BEGIN;

ALTER TABLE reportgrouparbitrary ADD COLUMN primaryreport integer(11);
ALTER TABLE reportgrouptestrun ADD COLUMN primaryreport integer(11);
ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;

COMMIT;
