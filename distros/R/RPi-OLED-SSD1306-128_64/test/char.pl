use strict;
use warnings;

use Test::More;

use RPi::OLED::SSD1306::128_64;

my $s = RPi::OLED::SSD1306::128_64->new;

$s->clear;

$s->char(0, 15, 14, 4); # music note double
$s->char(30, 15, 3, 4); # heart
$s->char(60, 15, 168, 4); # upside down ?
$s->char(90, 15, 157, 4); # weird symbol
#$s->char(90, 15, 0xA9, 4); # copyright ???

$s->display;

done_testing();

