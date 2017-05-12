use strict;
use warnings;

use Test::More;

use PerlGSL::RootFinding::SingleDim qw/findroot_1d/;

is( findroot_1d( sub{ 2 * $_[0] - 10 }, 0, 10 ), 5, "linear algebraic" );

my $res = sprintf "%.4f", findroot_1d( sub{ $_[0]**2 - 7 }, 0, 3 );
is( $res, sprintf("%.4f", sqrt(7)), "quadratic" );

done_testing;

