-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010031-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010032-SQLite.sql':;

BEGIN;

ALTER TABLE host ADD COLUMN comment VARCHAR(255) DEFAULT '';


COMMIT;

