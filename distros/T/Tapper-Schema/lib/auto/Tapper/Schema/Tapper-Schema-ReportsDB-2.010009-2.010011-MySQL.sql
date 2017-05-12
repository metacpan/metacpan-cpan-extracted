-- Convert schema '/var/tmp/Tapper-Schema-ReportsDB-2.010009-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010011':

BEGIN;

ALTER TABLE reportcomment CHANGE COLUMN created_at created_at datetime NOT NULL,
                          CHANGE COLUMN updated_at updated_at datetime NOT NULL;
ALTER TABLE reportfile ADD COLUMN created_at datetime NOT NULL,
                       ADD COLUMN updated_at datetime NOT NULL;
ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;

COMMIT;
