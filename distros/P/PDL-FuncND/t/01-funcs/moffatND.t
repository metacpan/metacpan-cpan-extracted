#!perl

use PDL;
use PDL::MatrixOps;
use PDL::Transform;

use Math::Trig qw[ pi ];

use Test::More;

use PDL::FuncND;


use strict;
use warnings;

our $N = 5;

my $alpha = 3;
my $beta  = 2.4;

sub _gamma { exp( ( lgamma( @_ ) )[0] ) }

sub nfact {

    my ( $s, $beta, $n ) = @_;

    my $alpha_n = ref $s && $s->nelem > 1 ? sqrt( determinant($s)) : $s**$n;

    my $norm = _gamma( $beta )
      / _gamma( $beta - $n / 2 )
      / ( pi**( $n / 2 ) * $alpha_n );

    return $norm;
}

sub _moffat1D {

    my ( $x, $c, $a, $b ) = @_;

    my $r = abs( $x->[0] - $c->[0] );

    return 2 * $r * ( $b - 1 ) / ( $a * $a ) / ( 1 + ( $r / $a )**2 )**$b;

}

sub _moffatND_symmetric {

    my ( $x, $c, $b, $s ) = @_;

    my $ndims = @{$x};

    my $m;
    $m += ( ( $x->[$_] - $c->[$_] ) / $s )**2 for 0 .. $ndims - 1;

    my $norm = nfact($s, $b, $ndims);

    return $norm * ( 1 + $m )**( -$b );
}

sub _moffat2D {


    my ( $x, $c, $b, $s ) = @_;

    my $dx = $x->[0] - $c->[0];
    my $dy = $x->[1] - $c->[1];

    my ( $s00, $s01, $s10, $s11 ) = $s->list;

    my $norm = nfact($s, $b, 2);

#<<<  don't tidy
    return $norm *
      ( 1
	+  (   $dy * ($s00 * $dy - $s10 * $dx )
	     + $dx * ($s11 * $dx - $s01 * $dy )
	   ) / determinant( $s )
      )**-$b;
#>>>
}

# test 2D, symmetric
{

    my @c = ( $N / 2, $N / 2 ); #( 0.22, 1.93 );
    my $x = xvals( $N, $N );
    my $y = yvals( $N, $N );

    my $s = $alpha;

    my $exp = _moffatND_symmetric( [ $x, $y ], \@c, $beta, $s );

    my $got = moffatND(
        $x,
        {
            beta   => $beta,
            scale  => $s,
            center => \@c,
	    norm => 1,
        } );

    ok( all( approx( $got, $exp ) ), q[2D, symmetric] )
      or diag( "   got: $got\n    exp: $exp" );

    # test assymetric test code
    {
        my $s = identity( 2 ) * $s**2;
        my $got = _moffat2D( [ $x, $y ], \@c, $beta, $s );
        ok( all( approx( $got, $exp ) ),
            q[2D, symmetric, assymetric test code] )
          or diag( "   got: $got\n    exp: $exp" );
    }


    $got = moffatND(
        $x,
        {
            beta   => $beta,
            scale  => [ $s, $s ],
            center => \@c
        } );

    ok( all( approx( $got, $exp ) ), q[2D, symmetric, array] )
      or diag( "   got: $got\n    exp: $exp" );

}


# test 2D, symmetric, transformed
{

    my @o = ( 8.3, 7.7 );
    my @m = ( 1.1, 3.9 );

    my @c = ( 0.22, 1.93 );

    my $x = $m[0] * ( xvals( $N, $N ) + $o[0] );
    my $y = $m[1] * ( yvals( $N, $N ) + $o[1] );

    my $t = t_linear( { scale => pdl( @m ), offset => pdl( @o ) } );

    my $s = $alpha;

    my $exp = _moffatND_symmetric( [ $x, $y ], \@c, $beta, $s );

    my $got = moffatND(
        $x,
        {
            beta      => $beta,
            scale     => $s,
            center    => \@c,
            transform => $t,
        } );

    ok( all( approx( $got, $exp ) ), q[2D, symmetric transformed] )
      or diag( "   got: $got\n    exp: $exp" );

}

# test 2D, general
{

    my @c = ( 2.2, 9.3 );
    my $x = xvals( $N, $N );
    my $y = yvals( $N, $N );

    my $s = pdl( [ 1, 2 ], [ 3, 8 ] );

    my $exp = _moffat2D( [ $x, $y ], \@c, $beta, $s );

    my $got = moffatND(
        $x,
        {
            scale  => $s,
            center => \@c,
            beta   => $beta
        } );

    ok( all( approx( $got, $exp ) ), q[2D] )
      or diag( "   got: $got\n    exp: $exp" );


}

# test 3D, symmetric
{

    my @c = ( 0.22, 1.93, 9.847 );
    my $x = xvals( $N, $N, $N );
    my $y = yvals( $N, $N, $N );
    my $z = zvals( $N, $N, $N );

    my $s = $alpha;

    my $exp = _moffatND_symmetric( [ $x, $y, $z ], \@c, $beta, $s );

    my $got = moffatND(
        $x,
        {
            beta   => $beta,
            scale  => $s,
            center => \@c
        } );

    ok( all( approx( $got, $exp ) ), q[3D, symmetric] )
      or diag( "   got: $got\n    exp: $exp" );


    $got = moffatND(
        $x,
        {
            beta   => $beta,
            scale  => [ $s, $s, $s ],
            center => \@c
        } );

    ok( all( approx( $got, $exp ) ), q[3D, symmetric, array] )
      or diag( "   got: $got\n    exp: $exp" );


}

done_testing;
