-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010018-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010021':;

BEGIN;

ALTER TABLE report ADD COLUMN tapdom LONGBLOB DEFAULT '',
                   CHANGE COLUMN tap tap LONGBLOB NOT NULL DEFAULT '';

ALTER TABLE reportgrouparbitrary CHANGE COLUMN arbitrary_id arbitrary_id VARCHAR(255) NOT NULL;

ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;


COMMIT;

