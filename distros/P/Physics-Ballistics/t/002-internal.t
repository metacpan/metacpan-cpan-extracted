#!/usr/bin/perl

# Unit tests for the Physics::Ballistics::Internal module.

use Test::Most;
use Data::Dumper;

use lib "./lib";
use Physics::Ballistics::Internal;

my $DEBUGGING = 0;

ok tween(cartridge_capacity( 5.7, 9.58, 44.7, 62500),  30,  32), "cartridge_capacity: 5.56x45mm";
ok tween(cartridge_capacity( 7.8, 11.9, 51.2, 60200),  53,  55), "cartridge_capacity: 7.62x51mm";
ok tween(cartridge_capacity(13.0, 20.4, 99.0, 55100), 289, 295), "cartridge_capacity: 12.7x99mm";

ok tween(empty_brass( 5.7, 9.58, 44.7, 62500),  94,  96), "empty_brass: 5.56x45mm";
ok tween(empty_brass( 7.8, 11.9, 51.2, 60200), 179, 183), "empty_brass: 7.62x51mm";
ok tween(empty_brass(13.0, 20.4, 99.0, 55100), 825, 835), "empty_brass: 12.7x99mm";

my $hr = gunfire(60200, 7.8, 24, 11.9, 51.2, 150);
ok tween($hr->{'N*m'}, 3400, 3600), "gunfire: 7.62x51mm muzzle energy";
ok tween($hr->{'f/s'}, 2780, 2790), "gunfire: 7.62x51mm muzzle velocity f/s";
ok tween($hr->{'m/s'},  835,  855), "gunfire: 7.62x51mm muzzle velocity m/s";

ok tween(ogival_volume (6, 1, 0.0), 0.0090, 0.0098), "ogival_volume: low drag for diameter";
ok tween(ogival_volume (6, 1, 0.3), 0.0100, 0.0109), "ogival_volume: low drag for volume";
ok tween(ogival_volume (6, 1, 0.6), 0.0111, 0.0119), "ogival_volume: high volume";

ok tween(powley(0.224, 0.378, 1.77, 24, 16), 0.9200, 0.9210), "powley ratio";

ok tween(cup2psi_linear(52450), 61500, 61700), "cup2psi_linear";

ok tween(cup2psi(52450), 62600, 62900), "cup2psi";

ok tween(recoil_mbt(1290, 5.5, 1650), 47, 51), "recoil_mbt: M256, M829";

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
