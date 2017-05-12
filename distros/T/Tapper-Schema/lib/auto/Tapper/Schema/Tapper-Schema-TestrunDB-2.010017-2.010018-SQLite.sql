-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010017-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010018-SQLite.sql':;

BEGIN;

ALTER TABLE host ADD COLUMN active TINYINT DEFAULT '0';


COMMIT;

