#!/usr/bin/perl

# Unit tests for the Physics::Ballistics::External module.

use Test::Most;
use Data::Dumper;

use lib "./lib";
use Physics::Ballistics::External;

my $DEBUGGING = 0;

ok tween(ebc( 72, 0.224, 'amax'   )->{bc}, 0.389, 0.393), "ebc: G1 BC of 5.56mm 72g AMAX";
ok tween(ebc(147, 0.308, 'spitzer')->{bc}, 0.385, 0.391), "ebc: G1 BC of 7.62mm 147g spitzer";
ok tween(ebc(155, 0.312, '7n1'    )->{bc}, 0.443, 0.450), "ebc: G1 BC of .312 155g 7N1";

my $ar = flight_simulator('G1', 0.375, 2400, 1.0, 3, -1, 300, 20, 30, 300);
ok tween($ar->[  0]->{vel_fps}, 2399, 2401), "flight_simulator: velocity at 0 yards";
ok tween($ar->[100]->{vel_fps}, 2174, 2178), "flight_simulator: velocity at 100 yards";
ok tween($ar->[200]->{vel_fps}, 1960, 1970), "flight_simulator: velocity at 200 yards";
ok tween($ar->[300]->{vel_fps}, 1750, 1780), "flight_simulator: velocity at 300 yards";

ok tween(g1_drag(4500), 2050, 2090), "g1_drag: very high velocity drop";
ok tween(g1_drag(3500), 1260, 1290), "g1_drag: high velocity drop";
ok tween(g1_drag(2500),  705,  735), "g1_drag: medium velocity drop";
ok tween(g1_drag(1500),  290,  320), "g1_drag: low velocity drop";
ok tween(g1_drag( 400),    6,    8), "g1_drag: subsonic velocity drop";

ok tween(muzzle_energy(150, 2400, 0), 1910, 1925), "muzzle_energy: foot-pounds";
ok tween(muzzle_energy(150, 2400, 1), 2585, 2615), "muzzle_energy: joules";

ok tween(muzzle_velocity_from_energy(150, 1917), 2385, 2415), "muzzle_velocity_from_energy";

done_testing();
exit(0);

sub tween {  # because floating point numbers are tricksy
  my $cmp1 = $_[0] > $_[1];
  my $cmp2 = $_[0] < $_[2];
  my $cmp3 = $cmp1 && $cmp2;
  print "# $_[0] > $_[1] == $cmp1\n" if $DEBUGGING;
  print "# $_[0] < $_[2] == $cmp2\n" if $DEBUGGING;
  print "# $cmp1 && $cmp2 == $cmp3\n" if $DEBUGGING;
  print STDERR "# tween: $_[0] not between $_[1] and $_[2]\n" unless($cmp3);
  return $cmp3;
}
