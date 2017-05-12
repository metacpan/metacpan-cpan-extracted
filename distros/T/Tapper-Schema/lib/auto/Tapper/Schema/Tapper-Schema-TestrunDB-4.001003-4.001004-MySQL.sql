-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001003-MySQL.sql' to 'Tapper::Schema::TestrunDB v4.001004':;

BEGIN;

ALTER TABLE message CHANGE COLUMN message message text,
                    CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE preconditiontype CHANGE COLUMN name name VARCHAR(255) NOT NULL;

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testrun ADD INDEX testrun_idx_created_at (created_at);

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare',
                               ADD INDEX testrun_scheduling_idx_created_at (created_at);


COMMIT;

