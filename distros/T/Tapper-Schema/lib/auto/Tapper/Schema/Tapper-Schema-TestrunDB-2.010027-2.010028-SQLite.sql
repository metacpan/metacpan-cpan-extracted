-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010027-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010028-SQLite.sql':;

BEGIN;

ALTER TABLE queue ADD COLUMN active INT(1) DEFAULT '0';


COMMIT;

