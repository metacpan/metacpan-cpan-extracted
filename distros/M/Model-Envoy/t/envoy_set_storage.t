use lib 't/lib';

package My::Envoy::Models;

use Moose;
with 'Model::Envoy::Set' => { namespace => 'My::Envoy' };

1;

package main;

use Test::More;
use My::Envoy::Widget;
use My::Envoy::Part;
use My::DB;

my $schema = My::DB->db_connect;
$schema->deploy;

my $set = My::Envoy::Models->m('Widget');

is( $set->get_storage('DBIC'), 'Model::Envoy::Storage::DBIC');
isa_ok( $set->get_storage('DBIC')->schema, 'DBIx::Class::Schema');

done_testing;