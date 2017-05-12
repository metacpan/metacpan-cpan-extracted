-- Convert schema '/home/mhentsc3/perl510/lib/site_perl/5.10.0/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000001-MySQL.sql' to 'Tapper::Schema::TestrunDB v3.000001':;

BEGIN;

ALTER TABLE message CHANGE COLUMN message message text,
                    CHANGE COLUMN type type VARCHAR(255);

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

