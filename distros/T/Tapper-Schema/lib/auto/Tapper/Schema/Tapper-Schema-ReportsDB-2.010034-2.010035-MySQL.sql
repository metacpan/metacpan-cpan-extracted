-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010034-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010035':;

BEGIN;

ALTER TABLE tap ADD COLUMN tap_is_archive integer(11);


COMMIT;

