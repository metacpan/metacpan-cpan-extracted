use strict;
use lib 't/tlib';
use Test::More tests => 4;


BEGIN {
  use_ok( 'Object::Composer' );
}


my $obj = Object::Composer->load( 'Foo' );

isa_ok( $obj, 'Foo' );


my $obj2 = Object::Composer::load( 'Moo' );


isa_ok( $obj2, 'Moo' );
can_ok( $obj2, 'test' );


