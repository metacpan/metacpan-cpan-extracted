-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010019-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010021':;

BEGIN;

ALTER TABLE report CHANGE COLUMN tapdata tapdom LONGBLOB DEFAULT '';

ALTER TABLE reportgrouparbitrary CHANGE COLUMN arbitrary_id arbitrary_id VARCHAR(255) NOT NULL;

ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;


COMMIT;

