use strictures 2;

use DBI;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/lib";
use Net::Blossom::Server::Backend::S3;
use Net::Blossom::Server::Backend::S3::BlobStore;
use Net::Blossom::Server::Backend::SQLite::MetadataStore;
use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);
use TestS3Client;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
});

run_storage_contract_tests(
    name    => 'S3 bytes with SQLite metadata',
    factory => sub {
        $dbh->do('DROP TABLE IF EXISTS blossom_owners');
        $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
        my $metadata = Net::Blossom::Server::Backend::SQLite::MetadataStore->new(dbh => $dbh);
        my $client = TestS3Client->new;
        my $generation = 0;
        my $storage = Net::Blossom::Server::Backend::S3->new(
            metadata_store => $metadata,
            blob_store => Net::Blossom::Server::Backend::S3::BlobStore->new(
                client     => $client,
                temp_dir   => tempdir(CLEANUP => 1),
                generation => sub { 'sqlite-' . ++$generation },
                range_size => 7,
            ),
            base_url => 'https://cdn.example.test',
        );
        $storage->deploy_schema;
        return $storage;
    },
);

done_testing;
