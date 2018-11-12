#!perl

use Test2::V0;
use Test::Lib;

use Container1;


Container1::run_shadow_attrs( attrs => [ 'a' ], private => 1 );

my $obj = Container1->new( a => 3 );
like( dies { $obj->a }, qr/can't locate object method/i,  'mangled attribute name' );

is ( $obj->foo->a, 3, 'contained attribute' );

done_testing;
