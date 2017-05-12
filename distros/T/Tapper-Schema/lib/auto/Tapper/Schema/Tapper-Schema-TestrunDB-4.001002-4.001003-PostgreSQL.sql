-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001002-PostgreSQL.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001003-PostgreSQL.sql':;

BEGIN;

ALTER TABLE host ADD CONSTRAINT constraint_name UNIQUE (name);


COMMIT;

