-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000006-MySQL.sql' to 'Tapper::Schema::ReportsDB v3.000007':;

BEGIN;

ALTER TABLE notification DROP COLUMN `condition`,
                         ADD COLUMN filter text NOT NULL;

ALTER TABLE notification_event CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE user ADD UNIQUE unique_login (login);


COMMIT;

