#! perl

use PDL;
use PDL::MatrixOps;

use Test::More tests => 7;

BEGIN {
  use_ok('PDL::FuncND');
}

use strict;
use warnings;

our $N = 99;

# 2D tests

{
    my $cov = identity( 2 );

    # d = x**2 + y**2
    my $d0 = rvals( $N, $N, { center => [0,0], squared => 1 } );
    ok( all ( $d0 == t2d( $cov ) ), "identity" );

    # identity matrix is it's own inverse
    ok( all ( $d0 == t2d( $cov, opts => { inverted => 1 } ) ), "identity" );

    # explicit centering w/ (0, 0)
    ok( all ( $d0 == t2d( $cov, opts => { center => [0,0] } ) ), "identity, [ 0, 0 ]" );
}

# specific center

{
    my $cov = identity( 2 );
    my $d0 = rvals( $N, $N, { center => [1.2, 2.2], squared => 1 } );


    # From CPAN testers:
    # OpenBSD (5.4) 32 bit boxes gives (min,max) = -3.63797880709171e-12, 3.63797880709171e-12.
    # Other 32 bit boxes and all 64 bit boxes work with an epsilon of 2e-14.

    my $got = t2d( $cov, opts => { center => [ 1.2, 2.2 ] } );
    ok( all ( approx( $d0, $got, 4e-12) ),
	"identity, [1.2, 2.2]" )
      or diag( "min, max diff (exp-got): ",
		join( ', ', ($d0 -$got)->minmax),
		"\n" );

    $got = t2d( $cov, opts => { center => pdl([ 1.2, 2.2 ]) } ),
    ok( all ( approx( $d0, $got, 4e-12) ),
	"identity, pdl [1.2, 2.2]"
      )
      or diag( "min, max diff (exp-got): ",
		join( ', ', ($d0 -$got)->minmax),
		"\n" );
}

# flip covariance; d = 2 * x * y.  this is not a true covariance matrix; just checking that the code works
# eventually when the input cov matrix is checked, this test will have to be rewritten
{
    my $cov = 1 - identity( 2 );
    my $c = [ 1.2, 2.2 ];
    my $d0 = 2 * ( (xvals( $N, $N ) - $c->[0] ) * (yvals( $N, $N ) - $c->[1] ) );
    ok( all ( $d0 == t2d( $cov, opts => { center => [ 1.2, 2.2 ] } ) ),
	"x<>y, [1.2, 2.2]" );
}


sub t2d {

    my ( $cov, %opt ) = @_;

    $opt{opts} ||= {};

    my $N = $opt{N} || $N;

    # generate an NxN set of indices
    my $x = $opt{x} || sequence($N);
    my $y = $opt{y} || sequence($N);


    # this mess creates a list of NXN  2X1 vectors
    my $v = append( $y->dummy(-1,$N)->flat->transpose,
		    $x->dummy(0,$N)->flat->transpose
	);

    return  mahalanobis( $v, $cov, { %{$opt{opts}}, squared => 1 } )->reshape( $N, $N);
}
