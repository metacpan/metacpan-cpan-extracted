#!/usr/bin/env perl

use Test::More tests => 18;

use Statistics::Standard_Normal 'z_to_pct';

sub pct_ca {
    my ( $arg, $exp ) = @_;
    my $got = z_to_pct($arg);
    $got = $exp if abs( $got - $exp ) < 0.1;
    is( $got, $exp, "Percentile for z = $arg" );
}

ok( !defined( z_to_pct() ), 'no argument' );

pct_ca( -4,    0.1 );
pct_ca( -3,    0.1 );
pct_ca( -2.5,  0.6 );
pct_ca( -2,    2.3 );
pct_ca( -1.5,  6.7 );
pct_ca( -1,    15.9 );
pct_ca( -0.5,  30.9 );
pct_ca( -0.25, 40.1 );
pct_ca( 0,     50 );
pct_ca( 0.25,  59.8 );
pct_ca( 0.5,   69.1 );
pct_ca( 1,     84.1 );
pct_ca( 1.5,   93.3 );
pct_ca( 2,     97.7 );
pct_ca( 2.5,   99.4 );
pct_ca( 3,     99.9 );
pct_ca( 4,     99.9 );
