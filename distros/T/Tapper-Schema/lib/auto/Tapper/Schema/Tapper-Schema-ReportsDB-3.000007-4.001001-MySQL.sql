-- Convert schema '/home/hmai/Projekte/Tapper/src/Tapper-Schema/lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000007-MySQL.sql' to 'Tapper::Schema::ReportsDB v4.001001':;

BEGIN;

SET foreign_key_checks=0;

ALTER TABLE user RENAME TO owner;


ALTER TABLE contact DROP FOREIGN KEY contact_fk_user_id,
                    DROP INDEX contact_idx_user_id,
                    CHANGE COLUMN user_id owner_id integer(11) NOT NULL,
                    ADD INDEX contact_idx_owner_id (owner_id),
                    ADD CONSTRAINT contact_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE notification DROP FOREIGN KEY notification_fk_user_id,
                         DROP INDEX notification_idx_user_id,
                         CHANGE COLUMN user_id owner_id integer(11),
                         ADD INDEX notification_idx_owner_id (owner_id),
                         ADD CONSTRAINT notification_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE notification_event CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE reportcomment DROP FOREIGN KEY reportcomment_fk_user_id,
                          DROP INDEX reportcomment_idx_user_id,
                          CHANGE COLUMN user_id owner_id integer(11),
                          ADD INDEX reportcomment_idx_owner_id (owner_id),
                          ADD CONSTRAINT reportcomment_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id);

SET foreign_key_checks=1;


COMMIT;

