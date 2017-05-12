#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't';

use Container1;


Container1::run_shadow_attrs( attrs => [ 'a' ], private => 1 );

my $obj = Container1->new( a => 3 );
dies_ok { $obj->a } 'mangled attribute name';

is ( $obj->foo->a, 3, 'contained attribute' );

done_testing;
