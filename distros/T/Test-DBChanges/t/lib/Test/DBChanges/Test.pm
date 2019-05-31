package Test::DBChanges::Test;
use strict;
use warnings;
use Test::PostgreSQL 1.27;
use Test::More;
use Test::Deep;
use Exporter 'import';
our @EXPORT = qw(pgsql assert_minimum_pgsql_version empty_changeset);

sub pgsql {
    return ( eval {
        Test::PostgreSQL->new(
            # settings suggested by the documentation
            pg_config => <<'EOF',
fsync = off
synchronous_commit = off
full_page_writes = off
bgwriter_lru_maxpages = 0
shared_buffers = 512MB
effective_cache_size = 512MB
work_mem = 100MB
EOF
            # don't do TCP
            unix_socket => 1,
            # init with our fixtures
            seed_scripts => [
                't/fixtures/schema-pg.sql',
                't/fixtures/data-pg.sql',
            ],
        );
    } or plan skip_all => $@ );
}

sub assert_minimum_pgsql_version {
    my ($dbh) = @_;

    my $version = $dbh->selectall_arrayref('SHOW server_version_num')->[0][0];
    $version >= 90400 or plan skip_all => "need PostgreSQL >= 9.4, this is $version";
}

sub empty_changeset {
    return methods(
        inserted_rows => [],
        updated_rows => [],
        deleted_rows => [],
    );
}

1;
