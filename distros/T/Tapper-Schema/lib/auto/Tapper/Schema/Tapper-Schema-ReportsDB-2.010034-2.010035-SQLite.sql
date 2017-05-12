-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010034-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010035-SQLite.sql':;

BEGIN;

ALTER TABLE tap ADD COLUMN tap_is_archive INT(11);


COMMIT;

