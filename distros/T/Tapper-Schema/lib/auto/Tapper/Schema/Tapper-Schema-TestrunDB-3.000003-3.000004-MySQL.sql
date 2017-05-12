-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000003-MySQL.sql' to 'Tapper::Schema::TestrunDB v3.000004':;

BEGIN;

ALTER TABLE host ADD COLUMN is_deleted TINYINT DEFAULT 0;

ALTER TABLE message CHANGE COLUMN message message text,
                    CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE queue ADD COLUMN is_deleted TINYINT DEFAULT 0;

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

