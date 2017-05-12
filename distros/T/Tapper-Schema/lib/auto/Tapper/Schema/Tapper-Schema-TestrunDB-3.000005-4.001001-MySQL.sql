-- Convert schema '/home/hmai/Projekte/Tapper/src/Tapper-Schema/lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000005-MySQL.sql' to 'Tapper::Schema::TestrunDB v4.001001':;

BEGIN;

SET foreign_key_checks=0;

ALTER TABLE user RENAME TO owner;

ALTER TABLE message CHANGE COLUMN message message text,
                    CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testrun DROP FOREIGN KEY testrun_fk_owner_user_id,
                    DROP INDEX testrun_idx_owner_user_id,
                    CHANGE COLUMN owner_user_id owner_id integer(11),
                    ADD INDEX testrun_idx_owner_id (owner_id),
                    ADD CONSTRAINT testrun_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id);

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';

SET foreign_key_checks=1;


COMMIT;

