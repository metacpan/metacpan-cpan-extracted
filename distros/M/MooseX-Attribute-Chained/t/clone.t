use strict;
use warnings;

package MyCloned;
use Moose;
use MooseX::Attribute::ChainedClone;

has foo => ( is => 'rw', traits => ['ChainedClone'] );
has writer =>
    ( is => 'rw', writer => 'set_writer', traits => ['ChainedClone'] );

package main;
use Scalar::Util qw(refaddr);
use Test::More;

is( MyCloned->meta->get_attribute("foo")->accessor_metaclass,
    'MooseX::Attribute::ChainedClone::Method::Accessor',
    'accessor metaclass set'
);

ok( my $object = MyCloned->new( foo => "init", writer => "init" ), "build object" );
ok( my $addr = refaddr $object, "get refaddr" );

{
    ok( my $clone = $object->foo("bar"), "set attribute and get clone" );
    is( $object->foo, "init", '$object keeps value' );
    is( $clone->foo,  "bar",  '$clone has new value' );
    ok( $clone->isa("MyCloned"), "isa object" );
    isnt( $addr, refaddr $clone, "refaddr doens't match" );
}

{
    ok( my $clone = $object->set_writer("bar"), "set writer attribute and get clone" );
    is( $object->writer, "init", '$object keeps value' );
    is( $clone->writer,  "bar",  '$clone has new value' );
    ok( $clone->isa("MyCloned"), "isa object" );
    isnt( $addr, refaddr $clone, "refaddr doens't match" );
}

done_testing;
