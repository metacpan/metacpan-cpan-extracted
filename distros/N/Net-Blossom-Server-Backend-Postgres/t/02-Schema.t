use strictures 2;

use Test::More;

use Net::Blossom::Server::Backend::Postgres;

my $dbh = _test_dbh();
_reset_schema($dbh);

my $storage = Net::Blossom::Server::Backend::Postgres->new(
    dbh      => $dbh,
    base_url => 'https://cdn.example.test',
);

ok($storage->deploy_schema, 'schema deploy succeeds');
ok($storage->deploy_schema, 'schema deploy is idempotent');

my @tables = sort map { $_->[0] } @{$dbh->selectall_arrayref(q{
    SELECT table_name
      FROM information_schema.tables
     WHERE table_schema = current_schema()
       AND table_name LIKE 'blossom_%'
})};
is_deeply(\@tables, [qw(blossom_blobs blossom_owners)], 'schema creates storage tables');

my ($index_exists) = $dbh->selectrow_array(q{
    SELECT 1
      FROM pg_indexes
     WHERE schemaname = current_schema()
       AND tablename = 'blossom_owners'
       AND indexname = 'blossom_owners_pubkey_order'
});
ok($index_exists, 'schema creates owner ordering index');

done_testing;

sub _test_dbh {
    my $dsn = $ENV{NET_BLOSSOM_POSTGRES_DSN}
        or plan skip_all => 'NET_BLOSSOM_POSTGRES_DSN is not set';

    eval 'use DBI (); use DBD::Pg (); 1'
        or die $@;

    return DBI->connect(
        $dsn,
        $ENV{NET_BLOSSOM_POSTGRES_USER},
        $ENV{NET_BLOSSOM_POSTGRES_PASSWORD},
        {
            AutoCommit    => 1,
            RaiseError    => 1,
            PrintError    => 0,
            pg_enable_utf8 => 0,
        },
    );
}

sub _reset_schema {
    my ($dbh) = @_;
    $dbh->do('DROP TABLE IF EXISTS blossom_owners');
    $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
    return;
}
