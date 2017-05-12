use strict;
use warnings;
use Test::More tests => 13;
use lib 't/tlib';

BEGIN {
  use_ok( 'Object::Composer' );
  can_ok( __PACKAGE__, 'load' );
}

my $obj = load 'Foo';

isa_ok( $obj, 'Foo', "instantiates correct object" );
can_ok( $obj, 'test' );
is( $obj->test, 'test' );


my $obj2 = load 'Moo', qw/a b c/, [ qw/b c d/ ], { e => 'f', g => 'h' };

isa_ok( $obj2, 'Moo' );
isa_ok( $obj2, 'Foo' );
can_ok( $obj2, 'test' );
can_ok( $obj2, 'arg_at' );


is( $obj2->arg_at( 0 ), 'a' );
is( $obj2->arg_at( 1 ), 'b' );
is_deeply( $obj2->arg_at( 3 ), [ qw/ b c d / ] );
is_deeply( $obj2->arg_at( 4 ), { qw/ e f g h / } );







