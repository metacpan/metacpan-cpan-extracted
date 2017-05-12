use strict;
use warnings;

use Test::More tests => 4;
use PerlGSL::Integration::MultiDim qw/int_multi/;

is(
  int_multi(sub{1}, [0,0], [5,4]), 
  20, 
  '\int_{0,0}^{5,4} dx dy'
);

my ($result, $error) = int_multi(sub{my ($x,$y) = @_; return $x**2 * $y}, [0,0], [3,4]);
is( sprintf("%.0f",$result), 72, '\int_{0,0}^{3,4} x^2 y dx dy' );
ok( abs( $result - 72 ) < $result, 'result within error estimate' );

my $piby4_integrand = sub { ($_[0]**2 + $_[1]**2) < 1 };
my ($piby4, $piby4_error) = int_multi( $piby4_integrand, [0,0], [1,1], {calls => 1e6} );
ok( abs( $piby4 - atan2(1,1) ) < $piby4_error, 'calculate Pi' );


