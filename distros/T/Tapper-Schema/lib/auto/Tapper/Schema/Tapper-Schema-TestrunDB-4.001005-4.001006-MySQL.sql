-- Convert schema '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001005-MySQL.sql' to 'Tapper::Schema::TestrunDB v4.001006':;

BEGIN;

ALTER TABLE host DROP COLUMN pool_count,
                 ADD COLUMN pool_free integer NULL,
                 ADD COLUMN pool_id integer NULL,
                 ADD INDEX host_idx_pool_id (pool_id),
                 ADD CONSTRAINT host_fk_pool_id FOREIGN KEY (pool_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE message CHANGE COLUMN message message text NULL,
                    CHANGE COLUMN type type VARCHAR(255) NULL;

ALTER TABLE state CHANGE COLUMN state state text NULL;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) NULL DEFAULT 'prepare';


COMMIT;

