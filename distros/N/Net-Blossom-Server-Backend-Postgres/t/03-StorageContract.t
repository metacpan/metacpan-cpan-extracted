use strictures 2;

use Test::More;

use Net::Blossom::Server::Backend::Postgres;
use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

my $dbh = _test_dbh();

run_storage_contract_tests(
    name    => 'Postgres backend storage',
    factory => sub {
        _reset_schema($dbh);
        my $storage = Net::Blossom::Server::Backend::Postgres->new(
            dbh      => $dbh,
            base_url => 'https://cdn.example.test',
        );
        $storage->deploy_schema;
        return $storage;
    },
);

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
