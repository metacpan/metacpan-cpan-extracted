use strictures 2;

use Test::More;

use_ok('Net::Blossom::Server::Backend::Postgres');
is($Net::Blossom::Server::Backend::Postgres::VERSION, '0.001000', 'version is declared');
can_ok('Net::Blossom::Server::Backend::Postgres', qw(new deploy_schema));

done_testing;
