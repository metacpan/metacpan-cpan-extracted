#!perl

use strict;
use warnings;

use Test::More;

use lib 't';

use Container1;

Container1::run_shadow_attrs( attrs => [ 'a' ],
			      fmt => sub { 'pfx_' . shift },
			      private => 0
			    );

my $obj = Container1->new( pfx_a => 3 );
is ( $obj->pfx_a, 3, 'container attribute' );
is ( $obj->foo->a, 3, 'contained attribute' );

done_testing;
