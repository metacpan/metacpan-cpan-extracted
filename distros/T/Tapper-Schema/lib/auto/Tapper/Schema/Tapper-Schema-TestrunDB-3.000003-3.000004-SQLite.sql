-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000003-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000004-SQLite.sql':;

BEGIN;

ALTER TABLE host ADD COLUMN is_deleted TINYINT DEFAULT 0;

ALTER TABLE queue ADD COLUMN is_deleted TINYINT DEFAULT 0;


COMMIT;

