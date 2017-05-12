# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Physics-Water-SoundSpeed.t'

#########################

use lib "../lib";

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Physics::Water::SoundSpeed') };

my $obj = new Physics::Water::SoundSpeed();

ok($obj, 'Create Object'); 

my $ss = $obj->sound_speed_t(10);

$exp_ft_10 = 1447.288999936;
ok(sprintf("%5.7f",$ss) == sprintf("%5.7f",$exp_ft_10), 'Sound Speed at 10c');

$exp_ftp_10_p101325  = 1447.27945667482;

$ss = $obj->sound_speed( 10,  .101325);
ok(sprintf("%5.7f",$ss) == sprintf("%5.7f",$exp_ftp_10_p101325),"Sound Speed at 10c and .101 Mpa" );

$exp_d2p_300 = 3.043425;
my $pres = $obj->d2p_fresh( [0, 100, 200, 300]);
ok(sprintf("%5.7f",$pres->[3]) == sprintf("%5.7f",$exp_d2p_300),"Pressure at 300m" );

my $exp_sea_t5_p1_s35 = 1472.3718861444;
$ss = $obj->sound_speed_sea_tps(5,1,35);

#{print "\nDUDE $ss != $exp_sea_t5_p1_s35 \n\n"; exit;}

ok(sprintf("%5.10f",$ss) == sprintf("%5.10f",$exp_sea_t5_p1_s35),"Sound Speed Sea Water at 5C, 1Mpa, 35 ppm exp=$exp_sea_t5_p1_s35 got $ss" );

my $exp_sea_t4_p7_s55 = 1504.19426793484;
$ss = $obj->sound_speed_sea_tps(4, 7, 55);
ok(sprintf("%5.10f",$ss) == sprintf("%5.10f",$exp_sea_t4_p7_s55),"Sound Speed Sea Water at 4C, 7Mpa, 55 ppm exp=$exp_sea_t4_p7_s55 got $ss" );

my $obj_us = new Physics::Water::SoundSpeed('units'=>'US');

my $ss_us = sprintf("%5.3f", $obj_us->sound_speed_t(41));
my $ss_si = sprintf("%5.3f", $obj->sound_speed_t(5) / 0.3048);
ok($ss_us == $ss_si,"Sound Speed using US units" );


