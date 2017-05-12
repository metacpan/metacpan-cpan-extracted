-- Convert schema '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001006-SQLite.sql' to '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001007-SQLite.sql':;

BEGIN;

ALTER TABLE scenario ADD COLUMN options TEXT;

ALTER TABLE scenario ADD COLUMN name VARCHAR;


COMMIT;

