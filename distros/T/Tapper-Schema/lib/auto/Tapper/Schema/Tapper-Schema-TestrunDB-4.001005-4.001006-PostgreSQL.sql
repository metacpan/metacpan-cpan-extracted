-- Convert schema '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001005-PostgreSQL.sql' to '/home/local/ANT/caldrin/perl5/perls/perl-5.16.2/lib/site_perl/5.16.2/auto/Tapper/Schema/Tapper-Schema-TestrunDB-4.001006-PostgreSQL.sql':;

BEGIN;

ALTER TABLE host DROP COLUMN pool_count;

ALTER TABLE host ADD COLUMN pool_free integer;

ALTER TABLE host ADD COLUMN pool_id integer;

CREATE INDEX host_idx_pool_id on host (pool_id);

ALTER TABLE host ADD CONSTRAINT host_fk_pool_id FOREIGN KEY (pool_id)
  REFERENCES host (id) ON DELETE cascade ON UPDATE cascade DEFERRABLE;


COMMIT;

