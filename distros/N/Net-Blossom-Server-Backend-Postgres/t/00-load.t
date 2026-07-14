use strictures 2;

use Test::More;

use_ok('Net::Blossom::Server::Backend::Postgres');
use_ok('Net::Blossom::Server::Backend::Postgres::MetadataStore');
use_ok('Net::Blossom::Server::Backend::Postgres::BlobStore');
is($Net::Blossom::Server::Backend::Postgres::VERSION, '0.001002', 'version is declared');
can_ok('Net::Blossom::Server::Backend::Postgres', qw(new deploy_schema));

done_testing;
