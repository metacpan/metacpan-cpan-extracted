#!/usr/bin/env perl

use Test::More tests => 13;

use Statistics::Standard_Normal 'pct_to_z';

sub z_ca {
    my ( $arg, $exp ) = @_;
    my $got = pct_to_z($arg);
    $got = $exp if abs( $got - $exp ) < 0.005;
    is( $got, $exp, "Z-score for $arg percentile" );
}

z_ca( 0,   -3.72 );    # Outer edge of approximation is 0.01%
z_ca( 1,   -2.33 );
z_ca( 3,   -1.88 );
z_ca( 5,   -1.64 );
z_ca( 10,  -1.28 );
z_ca( 25,  -0.674 );
z_ca( 50,  0 );
z_ca( 75,  0.674 );
z_ca( 90,  1.28 );
z_ca( 95,  1.64 );
z_ca( 97,  1.88 );
z_ca( 99,  2.33 );
z_ca( 100, 3.72 );
