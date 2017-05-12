-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010019-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010020':;

BEGIN;

ALTER TABLE testrun ADD INDEX testrun_idx_topic_name (topic_name),
                    ADD CONSTRAINT testrun_fk_topic_name FOREIGN KEY (topic_name) REFERENCES topic (name);

ALTER TABLE testrun_scheduling CHANGE COLUMN host_id host_id integer(11),
                               CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';

ALTER TABLE topic ENGINE=InnoDB;


COMMIT;

