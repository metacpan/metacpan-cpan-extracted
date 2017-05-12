#!/usr/bin/env perl

use Path::Hilbert;
use Test::Simple (tests => (1360 * 3));

for my $pow (0 .. 15) {
    for my $dec (0 .. 9) {
        my $frac = $dec / 10;
        my $n = 2 ** ($pow + $dec);
        for my $d (map { $_ + $dec } 0 .. $pow) {
            my ($x, $y) = d2xy($n, $d);
            my $e = xy2d($n, $x, $y);
            my ($x2, $y2) = d2xy($n, $e);
            ok(abs($d - $e) <= ($d / 100), "d $d -> ($x, $y) -> e $e (\$n == $n)");
            ok(abs($x - $x2) <= ($x / 100), "x $x ~~ $x2 (\$n == $n)");
            ok(abs($y - $y2) <= ($y / 100), "y $y ~~ $y2 (\$n == $n)");
            # ok(0, "d $d -> ($x, $y) e $e (\$n == $n)");
        }
    }
}
