use strictures 2;

use File::Temp qw(tempdir);
use Test::More;

use Net::Blossom::Server::Backend::SQLite;
use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

run_storage_contract_tests(
    name    => 'SQLite backend storage',
    factory => sub {
        my $dir = tempdir(CLEANUP => 1);
        my $storage = Net::Blossom::Server::Backend::SQLite->new(
            database => "$dir/blossom.sqlite",
            base_url => 'https://cdn.example.test',
        );
        $storage->deploy_schema;
        return $storage;
    },
);

done_testing;
