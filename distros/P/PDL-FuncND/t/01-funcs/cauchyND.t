#!perl

use PDL;
use PDL::MatrixOps;
use PDL::Transform;

use Math::Trig qw[ pi ];

use Test::More tests => 8;

BEGIN {
  use_ok('PDL::FuncND');
}

use strict;
use warnings;

our $N = 99;

sub _cauchy1D {

    my ( $x, $c, $s ) = @_;

    return $s / ( ($x - $c)**2 + $s**2) / pi;

}

sub _cauchy2D_symmetric {

    my ( $x, $y, $c, $s ) = @_;

    return $s / ( ( $x - $c->[0] )**2 + ( $y - $c->[1] )**2 + $s * $s) ** 1.5 / (2 * pi );

}

# General ND Cauchy
# from http://en.wikipedia.org/wiki/Cauchy_distribution#Multivariate_Cauchy_distribution
# courtesy of Maxima

#                                                              1 + k
#                                                        gamma(-----)
#                                                                2
#   f(x, u, S, k) := -------------------------------------------------------------------------------------
#                                                                                                    1 + k
#                                                                                                    -----
#                          1     k/2               1/2                                                 2
#                    gamma(-) %pi    determinant(S)    (1 + transpose(x - u) . (invert(S) . (x - u)))
#                          2
#

# 2D form:

# f(matrix([x,y]),matrix([x0,y0]),matrix([s00,s01],[s10,s11]),2):

#                                                            0.1591549430919
#  -----------------------------------------------------------------------------------------------------------------------------------
#                     0.5     s00 (y - y0)        s10 (x - x0)                            s11 (x - x0)        s01 (y - y0)         1.5
#  (s00 s11 - s01 s10)    ((----------------- - -----------------) (y - y0) + (x - x0) (----------------- - -----------------) + 1)
#                           s00 s11 - s01 s10   s00 s11 - s01 s10                       s00 s11 - s01 s10   s00 s11 - s01 s10
#

# Fortran
#      1.5915494309189535E-1/((s00*s11-s01*s10)**5.0E-1*((s00*(y-y0)/(s00
#     1   *s11-s01*s10)-s10*(x-x0)/(s00*s11-s01*s10))*(y-y0)+(x-x0)*(s11*
#     2   (x-x0)/(s00*s11-s01*s10)-s01*(y-y0)/(s00*s11-s01*s10))+1)**1.5E
#     3   +0)
#



# Perl
sub _cauchy2D {

    my ( $x, $y, $c, $s ) = @_;

    my ($x0, $y0) = @$c;
    my ( $s00, $s01, $s10, $s11 ) = $s->list;


    return 1.5915494309189535E-1/(($s00*$s11-$s01*$s10)**5.0E-1*(($s00*($y-$y0)/($s00
        *$s11-$s01*$s10)-$s10*($x-$x0)/($s00*$s11-$s01*$s10))*($y-$y0)+($x-$x0)*($s11*
        ($x-$x0)/($s00*$s11-$s01*$s10)-$s01*($y-$y0)/($s00*$s11-$s01*$s10))+1)**1.5E+0);


}

# test 1D
{
    my $c = 2.2;
    my $x = sequence($N);
    my $s = 3;


    my $f = _cauchy1D( $x, $c, $s );
    my $g = cauchyND( $x, { scale => $s, center => $c } );

    ok( all ( approx($g, $f) ), "1D" );
}

# test 1D, transformed
{
    my $c = 2.2;
    my $x = 1.3 * ( sequence($N) + 1.9 );
    my $s = 3;

    my $t = t_linear( { scale => 1.3, offset => 1.9, dims => 1 } );

    my $f = _cauchy1D( $x, $c, $s );
    my $g = cauchyND( $x, { scale => $s, center => $c, transform => $t } );

    ok( all ( approx($g, $f) ), "1D, transformed" );
}


# test 2D, symmetric
{

    my @c = ( 2.2, 9.3);
    my $x = xvals($N, $N);
    my $y = yvals($N, $N);

    my $s = 3;

    my $f = _cauchy2D_symmetric( $x, $y, \@c, $s );

    my $g = cauchyND( $x, { scale => $s, center => \@c } );

    ok( all ( approx($g, $f) ), q[2D, symmetric] );


    $g = cauchyND( $x, { scale => [$s,$s], center => \@c } );

    ok( all ( approx($g, $f) ), q[2D, symmetric, array] );


}

# test 2D, symmetric, transformed
{
    my @o = ( 8.3, 7.7 );
    my @m = ( 1.1, 3.9 );

    my @c = ( 2.2, 9.3);
    my $x = $m[0] * ( xvals($N,$N) + $o[0] );
    my $y = $m[1] * ( yvals($N,$N) + $o[1] );

    my $t = t_linear( { scale => pdl( @m ), offset => pdl( @o ) } );

    my $s = 3;

    my $f = _cauchy2D_symmetric( $x, $y, \@c, $s );

    my $g = cauchyND( $x, { scale => $s, center => \@c, transform => $t } );

    ok( all ( approx($g, $f) ), "2D symmetric, transformed" );
}


# test 2D, general
{

    my @c = ( 2.2, 9.3);
    my $x = xvals($N,$N);
    my $y = yvals($N,$N);

    my $s = pdl( [1,2], [3,8] );

    my $f = _cauchy2D( $x, $y, \@c, $s );

    my $g = cauchyND( $x, { scale => $s, center => \@c } );

    ok( all ( approx($g, $f) ), q[2D] );


}


# test 2D, general, transformed
{
    my @o = ( 8.3, 7.7 );
    my @m = ( 1.1, 3.9 );

    my @c = ( 2.2, 9.3);
    my $x = $m[0] * ( xvals($N,$N) + $o[0] );
    my $y = $m[1] * ( yvals($N,$N) + $o[1] );

    my $s = pdl( [1,2], [3,8] );

    my $t = t_linear( { scale => pdl( @m ), offset => pdl( @o ) } );

    my $f = _cauchy2D( $x, $y, \@c, $s );

    my $g = cauchyND( $x, { scale => $s, center => \@c, transform => $t } );

    ok( all ( approx($g, $f) ), "2D general, transformed" );
}

