use strict;
use warnings;

use Test::More tests => 5;
use PerlGSL::Integration::SingleDim qw/int_1d/;

is( int_1d(sub{1}, 0, 5), 5, '\int_0^5 dx' );
is( int_1d(sub{1}, 0, 5, {engine => 'fast'}), 5, '\int_0^5 dx (fast)' );

my $gaussian = sub{ exp( -($_[0]**2) ) };
my $exact  = 2 * sqrt( atan2(1,1) );

{
  my $result = sprintf "%0.5f", scalar int_1d($gaussian, '-Inf', 'Inf');
  my $expect = sprintf "%0.5f", $exact;
  is( $result, $expect, 'Full infinite range gaussian' );
}

{
  my $result = sprintf "%0.5f", scalar int_1d($gaussian, 0, 'Inf');
  my $expect = sprintf "%0.5f", $exact / 2;
  is( $result, $expect, 'Positive half space infinite range gaussian' );
}

{
  my $result = sprintf "%0.5f", scalar int_1d($gaussian, '-Inf', 0);
  my $expect = sprintf "%0.5f", $exact / 2;
  is( $result, $expect, 'Negative half space infinite range gaussian' );
}

