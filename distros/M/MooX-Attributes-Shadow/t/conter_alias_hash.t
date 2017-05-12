#!perl

use strict;
use warnings;

use Test::More;

use lib 't';

use Container1;

Container1::run_shadow_attrs(
    attrs => {
        a => undef,
        b => 'xb'
    },
    fmt     => sub { 'pfx_' . shift },
    private => 0
);

my $obj = Container1->new(
    pfx_a => 3,
    xb    => 4
);
is( $obj->pfx_a,  3, 'container attribute: a' );
is( $obj->foo->a, 3, 'contained attribute: a' );

is( $obj->xb,     4, 'container attribute: b' );
is( $obj->foo->b, 4, 'contained attribute: b' );


done_testing;
