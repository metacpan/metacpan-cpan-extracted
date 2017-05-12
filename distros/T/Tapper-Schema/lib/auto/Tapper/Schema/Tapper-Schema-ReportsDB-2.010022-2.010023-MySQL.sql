-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010022-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010023':;

BEGIN;

ALTER TABLE reportsection ADD COLUMN changeset VARCHAR(255),
                          ADD COLUMN description VARCHAR(255),
                          CHANGE COLUMN language_description language_description text;


COMMIT;

