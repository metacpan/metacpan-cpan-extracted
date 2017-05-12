use Test::More 'no_plan';


package Bazzle;
use Storm::Object;
use MooseX::Types::Moose qw( Int Str );
use Test::More;

storm_table( 'Bazzle' );
is storm_table->name, 'Bazzle', q[set class table];

has 'identifier' => (
    is => 'rw',
    isa => Str,
    traits => [qw( PrimaryKey )],
);

has 'foo' => (
    is => 'rw',
    isa => Str,
);

has 'bar' => (
    is => 'rw',
    isa => Int,
);

has 'baz' => (
    is => 'rw',
    isa => Str,
);

ok __PACKAGE__->meta->get_attribute( $_ )->column, qq[$_ column created]
    for qw/foo bar baz/;

is __PACKAGE__->meta->get_attribute( $_ )->column->table->name, 'Bazzle', qq[$_ column table set]
    for qw/foo bar baz/;

is __PACKAGE__->meta->primary_key->name, 'identifier', 'primary key set';

package main;

my $o = Bazzle->new;
ok $o, 'object instantiated';