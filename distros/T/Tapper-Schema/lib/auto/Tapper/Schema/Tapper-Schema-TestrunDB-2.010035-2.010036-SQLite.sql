-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010035-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010036-SQLite.sql':;

BEGIN;

ALTER TABLE testplan_instance ADD COLUMN name VARCHAR(255) DEFAULT '';


COMMIT;

