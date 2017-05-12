#!perl

use strict;
use warnings;

use Test::More;

use lib 't';

use Container3;

Container3::run_shadow_attrs( private => 0 );

my $obj = Container3->new( a => 3 );
is ( $obj->a, 3, 'container attribute a' );
is ( $obj->foo->a, 3, 'contained attribute a' );

# make sure that b hasn't been wiped in the contained object as
# it hasn't been specified here

is ( $obj->foo->b, 'b', 'contained attribute b' );

is_deeply( [ sort $obj->foo->shadowable_attrs ], [ qw( a b ) ], 'shadowable attrs' );

done_testing;
