#!perl

use PDL;
use PDL::MatrixOps;
use PDL::Transform;

use Math::Trig qw[ pi ];

use Test::More tests => 10;

BEGIN {
  use_ok('PDL::FuncND');
}

use strict;
use warnings;

our $N = 99;

sub _gauss1D {

    my ( $x, $x0, $s ) = @_;

    return  exp( -( ($x - $x0)** 2) / $s ** 2 / 2) / sqrt( 2 * pi ) / $s;
}


sub _gauss2D {

    my ( $x, $y, $c, $s ) = @_;

    my $g0 = exp( -(   ($x - $c->[0]) ** 2 / $s->[0] **2
		     + ($y - $c->[1]) ** 2 / $s->[1] **2
		   ) / 2 ) / (2 * pi)**(2/2) / ($s->[0] * $s->[1]);

}

# test 1D Gaussian
{
    my $c = 2.2;
    my $x = sequence($N);
    my $s = 3;


    my $g0 = _gauss1D( $x, $c, $s );
    my $g = gaussND( $x, { scale => $s, center => $c } );

    ok( all ( approx($g, $g0) ), "1D Gaussian" );
}

# test 1D Gaussian, transformed
{
    my $c = 2.2;
    my $x = 1.3 * ( sequence($N) + 1.9 );
    my $s = 3;

    my $t = t_linear( { scale => 1.3, offset => 1.9, dims => 1 } );

    my $g0 = _gauss1D( $x, $c, $s );
    my $g = gaussND( $x, { scale => $s, center => $c, transform => $t } );

    ok( all ( approx($g, $g0) ), "1D Gaussian, transformed" );
}


# test 2D Gaussian, uncorrelated
{

    my @c = ( 2.2, 9.3);
    my $x = xvals($N,$N);
    my $y = yvals($N,$N);

    my @s = ( 3, 2 );

    my $g0 = _gauss2D( $x,  $y, \@c, \@s );

    my $g = gaussND( $x, { scale => \@s, center => \@c } );

    ok( all ( approx($g, $g0) ), "2D Gaussian, uncorrelated" );
}

# test 2D Gaussian, uncorrelated, transformed
{
    my @o = ( 8.3, 7.7 );
    my @m = ( 1.1, 3.9 );

    my @c = ( 2.2, 9.3);
    my $x = $m[0] * ( xvals($N,$N) + $o[0] );
    my $y = $m[1] * ( yvals($N,$N) + $o[1] );

    my $t = t_linear( { scale => pdl( @m ), offset => pdl( @o ) } );

    my @s = ( 3, 2 );

    my $g0 = _gauss2D( $x, $y, \@c, \@s );

    my $g = gaussND( $x, { scale => \@s, center => \@c, transform => $t } );

    ok( all ( approx($g, $g0) ), "2D Gaussian, uncorrelated, transformed" );
}


# test 2D Gaussian, correlated
{
    # this generates a 2D "rotated" Gaussian
    # see http://en.wikipedia.org/wiki/Gaussian_function#Two-dimensional_Gaussian_function


    # this is the inverse covariance matrix:
    #    [     2         2                          ]
    #    [  sin (t)   cos (t)   sin(2 t)   sin(2 t) ]
    #    [  ------- + -------   -------- - -------- ]
    #    [      2         2          2          2   ]
    #    [    sy        sx       2 sy       2 sx    ]
    #    [                                          ]
    #    [                          2         2     ]
    #    [ sin(2 t)   sin(2 t)   sin (t)   cos (t)  ]
    #    [ -------- - --------   ------- + -------  ]
    #    [      2          2         2         2    ]
    #    [  2 sy       2 sx        sx        sy     ]

    # and (thanks to maxima) this is the covariance matrix:
    #    [    2     2     2        2     2     2                ]
    #    [ (sx  - sy ) cos (t) + sy   (sy  - sx ) cos(t) sin(t) ]
    #    [                                                      ]
    #    [    2     2                    2     2     2        2 ]
    #    [ (sy  - sx ) cos(t) sin(t)  (sy  - sx ) cos (t) + sx  ]

    my @c = ( 2.2, 9.3);
    my $x = xvals($N,$N) - $c[0];
    my $y = yvals($N,$N) - $c[1];


    my @s = ( 3, 2 );

    my $t = pi / 3;

    my $icov = pdl( [ sin($t)**2/$s[1]**2 + cos($t)**2/$s[0]**2,
		      sin(2*$t)/(2*$s[1]**2)-sin(2*$t)/(2*$s[0]**2) ],
		    [ sin(2*$t)/(2*$s[1]**2)-sin(2*$t)/(2*$s[0]**2),
		      sin($t)**2/$s[0]**2+cos($t)**2/$s[1]**2 ]
		  );

    my $cov = pdl( [ ($s[0]**2-$s[1]**2)*cos($t)**2+$s[1]**2,
		     ($s[1]**2-$s[0]**2)*cos($t)*sin($t) ],
		   [ ($s[1]**2-$s[0]**2)*cos($t)*sin($t),
		     ($s[1]**2-$s[0]**2)*cos($t)**2+$s[0]**2] );

    my $a = $icov->at(0,0);
    my $b = $icov->at(0,1);
    my $c = $icov->at(1,1);

    my $g0 = exp( -(   $a * $x**2 + 2 * $b * $x * $y + $c * $y**2 ) / 2) / (2 * pi )**(2/2) / sqrt(determinant($cov));

    my $g = gaussND( $x, { scale => $cov, center => \@c } );

    ok( all ( approx($g, $g0) ), "2D Gaussian, correlated" );


    # now try with the explicit 2D theta code
    $g = gaussND( $x, { scale => \@s, theta => $t, center => \@c } );
    ok( all ( approx($g, $g0) ), "2D Gaussian, correlated, explicit theta" );
}


# test 3D Gaussian, uncorellated
{
    my $x = xvals($N,$N,$N);
    my $y = yvals($N,$N,$N);
    my $z = zvals($N,$N,$N);

    my @c = ( 2.2, 9.3, 8.1 );

    my @s = ( 3, 2, 5 );

    my $g0 = exp( -(   ($x - $c[0] )** 2 / $s[0] **2
		     + ($y - $c[1] )** 2 / $s[1] **2
		     + ($z - $c[2] )** 2 / $s[2] **2
		   ) / 2 ) / (2 * pi)**(3/2) / ( $s[0] * $s[1] * $s[2] );

    my $g = gaussND( $x, { scale => \@s, center => \@c } );

    ok( all ( approx($g, $g0) ), "3D Gaussian, uncorrelated" );
}

# test 3D Gaussian, uncorrelated, automatic center
{
    my $x = xvals($N,$N,$N);
    my $y = yvals($N,$N,$N);
    my $z = zvals($N,$N,$N);

    my @c = ( ($N-1)/2, ($N-1)/2, ($N-1)/2 );

    my @s = ( 3, 2, 5 );

    my $g0 = exp( -(   ($x - $c[0] )** 2 / $s[0] **2
		     + ($y - $c[1] )** 2 / $s[1] **2
		     + ($z - $c[2] )** 2 / $s[2] **2
		   ) / 2 ) / (2 * pi)**(3/2) / ( $s[0] * $s[1] * $s[2] );

    my $g = gaussND( $x, { scale => \@s, center => 'auto' } );

    ok( all ( approx($g, $g0) ), "3D Gaussian, uncorrelated, auto-center" );

}

# test 3D Gaussian, uncorrelated, automatic center, transformed
{
    my $t = t_linear( { scale => [2, 2, 2] , dims => 3 } );

    my $x = xvals($N,$N,$N) * 2;
    my $y = yvals($N,$N,$N) * 2;
    my $z = zvals($N,$N,$N) * 2;

    my @c = ( $N-1, $N-1, $N-1 );

    my @s = ( 3, 2, 5 );

    my $g0 = exp( -(   ($x - $c[0] )** 2 / $s[0] **2
		     + ($y - $c[1] )** 2 / $s[1] **2
		     + ($z - $c[2] )** 2 / $s[2] **2
		   ) / 2 ) / (2 * pi)**(3/2) / ( $s[0] * $s[1] * $s[2] );

    my $g = gaussND( $x, { scale => \@s,
			   transform => $t,
			   center => 'auto' } );

    ok( all ( approx($g, $g0) ), "3D Gaussian, uncorrelated, auto-center, transformed" );

}
