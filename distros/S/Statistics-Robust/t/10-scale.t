#!perl -T

use Test::More tests => 7;
use Test::Number::Delta relative => 1e-4;
use Statistics::Robust::Scale qw(:all);

my $tol = 0.001;
my @x = (5,42,58,2,72,5,1,71,42,58,1,52,1,52,1,5,4);

my $mad = MAD(\@x);
delta_ok( $mad, 3.999994, 'MAD');

my $madn = MADN(\@x);
delta_ok( $madn ,5.9304, 'rescaled MAD');

my($ql,$qu) = idealf(\@x);

delta_ok( $ql, 1.666667, 'Ideal Fourths, Lower Quartile');
delta_ok( $qu, 54, 'Ideal Fourths, Upper Quartile');

my $winvar = winvar(\@x);
delta_ok( $winvar, 677.6544, 'Winsorized Variance');

my $pbvar = pbvar(\@x);
delta_ok( $pbvar, 1857.52662721893, 'Percentage Bend Midvariance');

my $trimse = trimvar(\@x);
delta_ok( $trimse, 110.7278, 'Variance of the Trimmed Mean');
