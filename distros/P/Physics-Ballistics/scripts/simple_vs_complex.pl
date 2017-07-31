#!/usr/bin/env perl

use lib "./lib";
use Physics::Ballistics::Terminal;

my ($mm1, $mm2, $mm3); # complex, complex sans stability, and simple penetration, respectively

# 7.62x54mmR light ball at various ranges vs mild steel

print "range  cpx  sim  cpx/stable\n";

$mm1 = pc(147, 2728,  50, 0.312, "ms", "mild");
$mm2 = pc(147, 2728, 500, 0.312, "ms", "mild");
$mm3 = pc_simple(147, 2728, 0.312, 'ms', 0.8);
print " 50m:  ".sprintf('%2.1f  %2.1f  %2.1f', $mm1, $mm3, $mm2)."\n";

$mm1 = pc(147, 2610, 100, 0.312, "ms", "mild");
$mm2 = pc(147, 2610, 500, 0.312, "ms", "mild");
$mm3 = pc_simple(147, 2610, 0.312, "ms", 0.8);
print "100m:  ".sprintf('%2.1f  %2.1f  %2.1f', $mm1, $mm3, $mm2)."\n";

$mm1 = pc(147, 2380, 200, 0.312, "ms", "mild");
$mm2 = pc(147, 2380, 500, 0.312, "ms", "mild");
$mm3 = pc_simple(147, 2380, 0.312, "ms", 0.8);
print "200m:  ".sprintf('%2.1f  %2.1f  %2.1f', $mm1, $mm3, $mm2)."\n";

$mm1 = pc(147, 2165, 300, 0.312, "ms", "mild");
$mm2 = pc(147, 2165, 500, 0.312, "ms", "mild");
$mm3 = pc_simple(147, 2165, 0.312, "ms", 0.8);
print "300m:  ".sprintf('%2.1f  %2.1f  %2.1f', $mm1, $mm3, $mm2)."\n";

$mm1 = pc(147, 1960, 400, 0.312, "ms", "mild");
$mm2 = pc(147, 1960, 500, 0.312, "ms", "mild");
$mm3 = pc_simple(147, 1960, 0.312, "ms", 0.8);
print "400m:  ".sprintf('%2.1f  %2.1f  %2.1f', $mm1, $mm3, $mm2)."\n";

$mm1 = pc(147, 1770, 500, 0.312, "ms", "mild");
$mm2 = pc(147, 1770, 500, 0.312, "ms", "mild");
$mm3 = pc_simple(147, 1770, 0.312, "ms", 0.8);
print "500m:  ".sprintf('%2.1f  %2.1f  %2.1f', $mm1, $mm3, $mm2)."\n";

exit(0);
