# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('OCBNET::WebSprite::Math') };

use OCBNET::WebSprite::Math qw(lcm gcf factors);

is join(",", factors(9)), "3,3", "factors(9) => 3,3";
is join(",", factors(50)), "2,5,5", "factors(50) => 2,5,5";

is join(",", lcm(3,5)), "15", "lcm(3,5) => 15";
is join(",", lcm(1,2,2)), "2", "lcm(1,2,2) => 2";
is join(",", lcm(20,60)), "60", "lcm(20,60) => 60";

is join(",", gcf(3,5)), "1", "gcf(3,5) => 1";
is join(",", gcf(1,2,2)), "1", "gcf(3,5) => 1";
is join(",", gcf(20,50)), "10", "gcf(20,50) => 10";
is join(",", gcf(20,60,5)), "5", "gcf(20,60,5) => 5";





