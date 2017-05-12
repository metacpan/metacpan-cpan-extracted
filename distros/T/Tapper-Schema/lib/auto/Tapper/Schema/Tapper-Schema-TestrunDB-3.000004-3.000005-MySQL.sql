-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000004-MySQL.sql' to 'Tapper::Schema::TestrunDB v3.000005':;

BEGIN;

ALTER TABLE message CHANGE COLUMN message message text,
                    CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testrun DROP FOREIGN KEY testrun_fk_testplan_id;

ALTER TABLE testrun ADD CONSTRAINT testrun_fk_testplan_id FOREIGN KEY (testplan_id) REFERENCES testplan_instance (id) ON UPDATE CASCADE;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

