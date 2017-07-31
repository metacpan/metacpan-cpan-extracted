#!/usr/bin/perl

# Unit tests for the Physics::Ballistics::Terminal module.

use Test::Most;
use Data::Dumper;

use lib "./lib";
use Physics::Ballistics::Terminal;

my $DEBUGGING = 0;

my $dop_cm = anderson(70, 2.5, 1.62, 0.6);
ok $dop_cm > 39.0 && $dop_cm < 40.0, "anderson: DTx: $dop_cm";

$dop_cm = anderson(78, 2.5, 1.65, 1.13);
ok $dop_cm > 80.5 && $dop_cm < 82.0, "anderson: M829A1: $dop_cm";

$dop_cm = anderson(10, 0.5, 1.55, 1.00);
ok $dop_cm >  7.0 && $dop_cm <  9.0, "anderson: hyp: $dop_cm";

$dop_cm = odermatt(78, 2.5, 1.65, 'du', 'steel', 17.5, 0, 175, 3, 7.86, 170);  # Improve on this; imperfect fit.
ok $dop_cm > 73.0 && $dop_cm < 76.0, "odermatt: M829A1: $dop_cm";

my ($int_cc, $ext_cc, $grams, $ccg) = boxes(100, 80, 30, 20, 15, 10, 5, 2, 7.86);
is $int_cc, 240000, "boxes: internal volume";
is $ext_cc, 499500, "boxes: external volume";
is $grams, 2039670, "boxes: mass";
ok $ccg > 0.10 && $ccg < 0.12, "boxes: internal volume per mass";

my $dop_mm = heat_dop(76, 2.7);
ok $dop_mm < 340 && $dop_mm > 300, "heat_dop: PG7V into RHA: $dop_mm";

$dop_mm = heat_dop(76, 2.6, 17.0);
ok $dop_mm < 240 && $dop_mm > 200, "heat_dop: PG7V into WHA: $dop_mm";

$dop_mm = heat_dop(76, 2.6, 7.86, 1);
ok $dop_mm < 420 && $dop_mm > 370, "heat_dop: precision charge: $dop_mm";

my $te = me2te(2.0, 1.2);
ok $te > 0.300 && $te < 0.310, "me2te: polycarbonate";

my $ce = me2ce(2.0, 4.0);
ok $ce > 1.8 && $ce < 2.0, "me2ce: polycarbonate";

my $cem = me2cem(2.0, 4.0);
ok $cem > 0.1 && $cem < 0.3, "me2cem: polycarbonate";

# assuming 7.62x51mm NATO M80 ball all-lead core from 24" barrel:

my $mm = pc(147, 2415, 100, 0.308, "bp", "pine");
ok tween($mm, 300.0, 1270.0), "pc:  M80 ball, 100m, pine: $mm mm";

$mm = pc(147, 2105, 200, 0.308, "bp", "pine");
ok tween($mm, 300.0, 1270.0), "pc:  M80 ball, 200m, pine: $mm mm";

$mm = pc(147, 1820, 300, 0.308, "bp", "pine");
ok tween($mm, 300.0, 1270.0), "pc:  M80 ball, 300m, pine: $mm mm";

$mm = pc(147, 1565, 400, 0.308, "bp", "pine");
ok tween($mm, 300.0, 1270.0), "pc:  M80 ball, 400m, pine: $mm mm";

$mm = pc(147,  970, 800, 0.308, "bp", "pine");
ok tween($mm, 300.0, 1270.0), "pc:  M80 ball, 800m, pine: $mm mm";


$mm = pc(147, 2415, 100, 0.308, "bp", "sand");
ok tween($mm, 100.0, 250.0), "pc:  M80 ball, 100m, sand: $mm mm";

$mm = pc(147, 2105, 200, 0.308, "bp", "sand");
ok tween($mm, 150.0, 350.0), "pc:  M80 ball, 200m, sand: $mm mm";

$mm = pc(147, 1565, 400, 0.308, "bp", "sand");
ok tween($mm, 100.0, 250.0), "pc:  M80 ball, 400m, sand: $mm mm";

$mm = pc(147,  970, 800, 0.308, "bp", "sand");
ok tween($mm,  50.0, 120.0), "pc:  M80 ball, 800m, sand: $mm mm";


$mm = pc(147, 2415, 100, 0.308, "bp", "brick");
ok tween($mm, 100.0, 700.0), "pc:  M80 ball, 100m, brick: $mm mm";

$mm = pc(147, 2105, 200, 0.308, "bp", "brick");
ok tween($mm, 100.0, 700.0), "pc:  M80 ball, 200m, brick: $mm mm";

$mm = pc(147, 1565, 400, 0.308, "bp", "brick");
ok tween($mm,  50.0, 700.0), "pc:  M80 ball, 400m, brick: $mm mm";

$mm = pc(147,  970, 800, 0.308, "bp", "brick");
ok tween($mm,  50.0, 700.0), "pc:  M80 ball, 800m, brick: $mm mm";


$mm = pc(147, 2415, 100, 0.308, "bp", "cinder");
ok tween($mm, 200.0, 300.0), "pc:  M80 ball, 100m, cinder: $mm mm";

$mm = pc(147, 2105, 200, 0.308, "bp", "cinder");
ok tween($mm, 150.0, 280.0), "pc:  M80 ball, 200m, cinder: $mm mm";

$mm = pc(147, 1565, 400, 0.308, "bp", "cinder");
ok tween($mm,  80.0, 200.0), "pc:  M80 ball, 400m, cinder: $mm mm";

$mm = pc(147,  970, 800, 0.308, "bp", "cinder");
ok tween($mm,  40.0, 120.0), "pc:  M80 ball, 800m, cinder: $mm mm";


$mm = pc(147, 2415, 100, 0.308, "bp", "mild");
ok tween($mm, 1.0, 700.0), "pc:  M80 ball, 100m, mild steel: $mm mm";

$mm = pc(147, 2105, 200, 0.308, "bp", "mild");
ok tween($mm, 1.0, 700.0), "pc:  M80 ball, 200m, mild steel: $mm mm";

$mm = pc(147, 1565, 400, 0.308, "bp", "mild");
ok tween($mm, 0.5, 700.0), "pc:  M80 ball, 400m, mild steel: $mm mm";

$mm = pc(147,  970, 800, 0.308, "bp", "mild");
ok tween($mm, 0.5, 700.0), "pc:  M80 ball, 800m, mild steel: $mm mm";


$mm = pc(147, 2415, 100, 0.308, "bp", "hard");
ok tween($mm, 1.0, 700.0), "pc:  M80 ball, 100m, hard steel: $mm mm";

$mm = pc(147, 2105, 200, 0.308, "bp", "hard");
ok tween($mm, 1.0, 700.0), "pc:  M80 ball, 200m, hard steel: $mm mm";

$mm = pc(147, 1565, 400, 0.308, "bp", "hard");
ok tween($mm, 0.5, 700.0), "pc:  M80 ball, 400m, hard steel: $mm mm";

$mm = pc(147,  970, 800, 0.308, "bp", "hard");
ok tween($mm, 0.3, 700.0), "pc:  M80 ball, 800m, hard steel: $mm mm";


$mm = pc(147, 2728, 50, 0.312, "ms", "mild");
ok tween($mm, 4.0, 7.0), "pc:  7.62x54mmR light ball at  50m vs mild steel: $mm mm";

$mm = pc(147, 2610, 100, 0.312, "ms", "mild");
ok tween($mm, 4.0, 8.5), "pc:  7.62x54mmR light ball at 100m vs mild steel: $mm mm";

$mm = pc(147, 2380, 200, 0.312, "ms", "mild");
ok tween($mm, 4.0, 9.5), "pc:  7.62x54mmR light ball at 200m vs mild steel: $mm mm";

$mm = pc(147, 2165, 300, 0.312, "ms", "mild");
ok tween($mm, 4.0, 8.0), "pc:  7.62x54mmR light ball at 300m vs mild steel: $mm mm";

$mm = pc(147, 1960, 400, 0.312, "ms", "mild");
ok tween($mm, 4.0, 7.0), "pc:  7.62x54mmR light ball at 400m vs mild steel: $mm mm";

$mm = pc(147, 1770, 500, 0.312, "ms", "mild");
ok tween($mm, 4.0, 6.5), "pc:  7.62x54mmR light ball at 500m vs mild steel: $mm mm";

$mm = pc_simple(147, 2105, 0.308, "bp");
ok tween($mm, 2.0, 5.0), "pc_simple:  M80 ball vs RHA: $mm mm";

$mm = pc_simple(150.5, 2055, 0.308, "sc");
ok tween($mm, 2.0, 5.0), "pc_simple:  M61 AP   vs RHA: $mm mm";

$mm = pc_simple(122, 2300, 0.308, "tc");  # M933 has muzzle velocity of about 2975fps
ok tween($mm, 5.5, 8.5), "pc_simple:  M993 TC  vs RHA: $mm mm";

$mm = pc_simple(147, 2105, 0.308, "wha");
ok tween($mm, 6.0, 9.0), "pc_simple:  7.62x51mm WHA vs RHA: $mm mm";

$mm = pc_simple(147, 2105, 0.308, "du");
ok tween($mm, 8.0, 9.5), "pc_simple:  7.62x51mm DU  vs RHA: $mm mm";

my $hits = hits_score(180, 1900, 0.308);
is 927, $hits, "HITS score";

my $sig = sigma(3, 4, 5, 6);
ok tween($sig, 1.11803, 1.11804), "sigma";

my $avg = average(3, 4, 5, 6);
ok tween($avg, 4.4, 4.6), "average";  # Can't test for == 4.5 because floating point :-P

my $x = rndto(1234.567,  2);
is 1200, $x, "rounding to nearest hundred";

$x = rndto(1234.567,  1);
is 1230, $x, "rounding to nearest ten";

$x = rndto(1234.567, -1);
ok tween($x, 1234.59, 1234.61), "rounding to nearest tenth";

$x = rndto(1234.567, -2);   # 1234.57
ok tween($x, 1234.569, 1234.571), "rounding to nearest hundredth";

$x = rndto(1234,     -2);
ok tween($x, 1233.999, 1234.001), "rounding a whole number is boring";

ok tween(r2d(1.0),  57.295,  57.296), "radians to degrees, first sector";
ok tween(r2d(2.0), 114.591, 114.592), "radians to degrees, second sector";
ok tween(r2d(4.0), 229.183, 229.184), "radians to degrees, fourth sector";

ok tween(d2r( 45), 0.785, 0.786), "degrees to radians, first sector";
ok tween(d2r(135), 2.356, 2.357), "degrees to radians, second sector";
ok tween(d2r(250), 4.362, 4.364), "degrees to radians, fourth sector";

is 5, poncelet(17, 400, 400, 50, 1.2, 0), "poncelet is no crappier than usual";

ok tween(te2me(0.306, 1.2), 1.95, 2.05), "te2me: polycarbonate";

ok tween(lethality( 63, 3100), 0.99, 1.01), "lethality: baseline";
ok tween(lethality(147, 2750), 2.06, 2.08), "lethality: 7.62x51mm point-blank";

ok tween(hv2bhn( 600), 556, 558), "hv2bhn: low end";
ok tween(hv2bhn( 900), 768, 770), "hv2bhn: mid-range";
ok tween(hv2bhn(1500), 863, 865), "hv2bhn: high end";

ok tween(bhn2hv(600),  645,  647), "bhn2hv: low end";
ok tween(bhn2hv(800),  986,  988), "bhn2hv: mid-range";
ok tween(bhn2hv(900), 1916, 1918), "bhn2hv: high end";

is hrc2bhn(14), undef, "hrc2bhn: out of bounds too low";
ok tween(hrc2bhn(18), 215, 219), "hrc2bhn: low end";
ok tween(hrc2bhn(34), 314, 318), "hrc2bhn: mid-range";
ok tween(hrc2bhn(50), 480, 484), "hrc2bhn: high end";
is hrc2bhn(66), undef, "hrc2bhn: out of bounds too high";

is bhn2hrc(190), undef, "bhn2hrc: out of bounds too low";
ok tween(bhn2hrc(250), 21, 23), "bhn2hrc: low end";
ok tween(bhn2hrc(450), 45, 47), "bhn2hrc: mid-range";
ok tween(bhn2hrc(650), 59, 61), "bhn2hrc: high end";
is bhn2hrc(780), undef, "bhn2hrc: out of bounds too high";

ok tween(psi2bhn( 75000), 149, 151), "psi2bhn: low end";
ok tween(psi2bhn(225000), 459, 462), "psi2bhn: mid-range";
ok tween(psi2bhn(375000), 743, 747), "psi2bhn: high end";

ok tween(bhn2psi(120),  59000,  61000), "bhn2psi: low end";
ok tween(bhn2psi(350), 174000, 176000), "bhn2psi: mid-range";
ok tween(bhn2psi(750), 386000, 389000), "bhn2psi: high end";

done_testing();
exit(0);

sub tween {  # because floating point numbers are tricksy
  my $cmp1 = $_[0] > $_[1];
  my $cmp2 = $_[0] < $_[2];
  my $cmp3 = $cmp1 && $cmp2;
  print "# $_[0] > $_[1] == $cmp1\n" if $DEBUGGING;
  print "# $_[0] < $_[2] == $cmp2\n" if $DEBUGGING;
  print "# $cmp1 && $cmp2 == $cmp3\n" if $DEBUGGING;
  return $cmp3;
}
