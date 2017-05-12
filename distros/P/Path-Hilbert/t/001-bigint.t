#!/usr/bin/env perl

use Path::Hilbert qw();
use Path::Hilbert::BigInt qw();
use Test::Simple (tests => (1360 * 3));

for my $pow (0 .. 15) {
    for my $dec (0 .. 9) {
        my $frac = $dec / 10;
        my $n = 2 ** ($pow + $dec);
        for my $d (map { $_ + $dec } 0 .. $pow) {
            my ($Sx, $Sy) = Path::Hilbert::d2xy($n, $d);
            my ($x, $y) = map { $_->numify() } Path::Hilbert::BigInt::d2xy($n, $d);
            my $e = Path::Hilbert::BigInt::xy2d($n, $x, $y)->numify();
            ok(abs($Sx - $x) <= ($Sx / 100), "X $x ~~ x $Sx (\$n == $n)");
            ok(abs($Sy - $y) <= ($Sy / 100), "Y $y ~~ y $Sy (\$n == $n)");
            ok(abs($d - $e) <= ($d / 100), "d $d -> ($x, $y) -> E $e (\$n == $n)");
            # ok(1, "d $d -> E $e (\$n == $n)");
        }
    }
}
