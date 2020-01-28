use Mojo::Base -strict;
use Test::More 0.98;

use_ok $_ for qw(
  Mojo::DB::Connector
  Mojo::DB::Connector::Role::Cache
  Mojo::DB::Connector::Role::ResultsRoles
);

done_testing;

