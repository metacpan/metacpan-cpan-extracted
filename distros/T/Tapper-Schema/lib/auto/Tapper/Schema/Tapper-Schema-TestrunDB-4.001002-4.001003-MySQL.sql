-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001002-MySQL.sql' to 'Tapper::Schema::TestrunDB v4.001003':;

BEGIN;

ALTER TABLE host ADD UNIQUE constraint_name (name);

ALTER TABLE message CHANGE COLUMN message message text NULL,
                    CHANGE COLUMN type type VARCHAR(255) NULL;

ALTER TABLE state CHANGE COLUMN state state text NULL;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) NULL DEFAULT 'prepare';


COMMIT;

