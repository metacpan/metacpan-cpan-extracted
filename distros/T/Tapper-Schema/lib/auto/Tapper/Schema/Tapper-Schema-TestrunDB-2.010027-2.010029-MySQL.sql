-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010027-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010029':;

BEGIN;

ALTER TABLE queue ADD COLUMN active integer(1) DEFAULT '0';

ALTER TABLE testrun_scheduling DROP COLUMN mergedqueue_seq,
                               ADD COLUMN prioqueue_seq integer(11),
                               CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

