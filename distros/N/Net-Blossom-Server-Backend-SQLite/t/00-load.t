use strictures 2;

use Test::More;

use_ok('Net::Blossom::Server::Backend::SQLite');
use_ok('Net::Blossom::Server::Backend::SQLite::MetadataStore');
use_ok('Net::Blossom::Server::Backend::SQLite::BlobStore');

is($Net::Blossom::Server::Backend::SQLite::VERSION, '0.001002', 'version is declared');
can_ok('Net::Blossom::Server::Backend::SQLite', qw(new deploy_schema));

done_testing;
