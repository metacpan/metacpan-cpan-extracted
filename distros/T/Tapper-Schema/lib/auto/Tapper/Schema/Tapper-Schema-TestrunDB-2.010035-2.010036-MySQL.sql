-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010035-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010036':;

BEGIN;

ALTER TABLE message CHANGE COLUMN message message text;

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testplan_instance ADD COLUMN name VARCHAR(255) DEFAULT '';

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

