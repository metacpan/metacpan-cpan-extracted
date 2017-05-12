-- Convert schema '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001004-SQLite.sql' to '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001005-SQLite.sql':;

BEGIN;

ALTER TABLE host ADD COLUMN pool_count INT;

CREATE INDEX testrun_scheduling_idx_stat00 ON testrun_scheduling (status);


COMMIT;

