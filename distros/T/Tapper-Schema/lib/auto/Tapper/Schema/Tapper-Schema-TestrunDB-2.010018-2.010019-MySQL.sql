-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010018-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010019':;

BEGIN;

ALTER TABLE testrun DROP FOREIGN KEY testrun_fk_topic_name,
                    DROP INDEX testrun_idx_topic_name;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';

ALTER TABLE topic;


COMMIT;

