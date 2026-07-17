use strictures 2;

use DBI;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib";
use Net::Blossom::Server::Backend::Filesystem;
use Net::Blossom::Server::Backend::SQLite::MetadataStore;
use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
});

run_storage_contract_tests(
    name    => 'filesystem bytes with SQLite metadata',
    factory => sub {
        $dbh->do('DROP TABLE IF EXISTS blossom_owners');
        $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
        my $generation = 0;
        my $storage = Net::Blossom::Server::Backend::Filesystem->new(
            metadata_store => Net::Blossom::Server::Backend::SQLite::MetadataStore->new(
                dbh => $dbh,
            ),
            root       => tempdir(CLEANUP => 1),
            generation => sub { 'sqlite-' . ++$generation },
            base_url   => 'https://cdn.example.test',
        );
        $storage->deploy_schema;
        return $storage;
    },
);

done_testing;
