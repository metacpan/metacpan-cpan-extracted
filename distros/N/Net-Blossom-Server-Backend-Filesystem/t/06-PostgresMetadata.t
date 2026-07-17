use strictures 2;

use File::Temp qw(tempdir);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib";
use Net::Blossom::Server::Backend::Filesystem;
use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

my $dbh = _test_dbh();

run_storage_contract_tests(
    name    => 'filesystem bytes with Postgres metadata',
    factory => sub {
        $dbh->do('DROP TABLE IF EXISTS blossom_owners');
        $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
        my $generation = 0;
        my $storage = Net::Blossom::Server::Backend::Filesystem->new(
            metadata_store => Net::Blossom::Server::Backend::Postgres::MetadataStore->new(
                dbh => $dbh,
            ),
            root       => tempdir(CLEANUP => 1),
            generation => sub { 'postgres-' . ++$generation },
            base_url   => 'https://cdn.example.test',
        );
        $storage->deploy_schema;
        return $storage;
    },
);

done_testing;

sub _test_dbh {
    my $dsn = $ENV{NET_BLOSSOM_POSTGRES_DSN}
        or plan skip_all => 'NET_BLOSSOM_POSTGRES_DSN is not set';

    eval 'use DBI (); use DBD::Pg (); use Net::Blossom::Server::Backend::Postgres::MetadataStore (); 1'
        or die $@;

    return DBI->connect(
        $dsn,
        $ENV{NET_BLOSSOM_POSTGRES_USER},
        $ENV{NET_BLOSSOM_POSTGRES_PASSWORD},
        {
            AutoCommit     => 1,
            RaiseError     => 1,
            PrintError     => 0,
            pg_enable_utf8 => 0,
        },
    );
}
