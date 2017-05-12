use Test::More 'no_plan';

package Foo::Bar;
use Storm::Object;
storm_table( 'FooBars' );

has 'id' => ( is => 'rw', isa => 'Str', traits => [qw( PrimaryKey )] );
has 'name' => ( is => 'rw' );

package Foo::Model;
use Storm::Model;

register 'Foo::Bar';

package main;
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->start_fresh;
$storm->aeolus->install_model( 'Foo::Model' );

ok ! $@, 'no errors';