#!perl -T

use strict;
use warnings;
use lib ();
use Test::More;
use Math::Cartesian::Product;

use Regexp::NumRange qw/rx_max/;

my $edges = [ 0, 1, 5, 9 ];

my @cases = cartesian { 1 } $edges, $edges;
@cases = cartesian { 1 } \@cases, $edges;
my @tests = map { my $n = join( '', @$_ ); [ $n, rx_max($n) ] } @cases;
my @edge_cases = map { $_->[0] - 1, $_->[0] + 0, $_->[0] + 1 } @tests;

foreach my $t (@tests) {
    my $n   = $t->[0];
    my $rxs = $t->[1];
    my $rx  = qr/^$rxs$/;
    foreach my $e (@edge_cases) {
        next unless $e >= 0;
        my $match = "$e" =~ $rx && int($e) =~ $rx;
        if ( $e <= $n ) {
            like "$e", $rx, "$e <= $n; '$e' should match: $rxs";
            like int($e), $rx, "$e <= $n; int($e) should match: $rxs";
        }
        else {
            unlike "$e", $rx, "$e > $n; '$e' should not match: $rxs";
            unlike int($e), $rx, "$e > $n; int($e) should not match: $rxs";
        }
    }
}

done_testing();

