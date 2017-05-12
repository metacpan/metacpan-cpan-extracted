#!perl

use strict;
use warnings;

use Test::More;

use lib 't';

use Container1;

Container1::run_shadow_attrs( attrs => [ 'a', 'b' ], private => 0 );

my $obj = Container1->new( a => 3 );
is ( $obj->a, 3, 'container attribute a' );
is ( $obj->foo->a, 3, 'contained attribute a' );

# make sure that b hasn't been wiped in the contained object as
# it hasn't been specified here

is ( $obj->foo->b, 'b', 'contained attribute b' );

done_testing;
