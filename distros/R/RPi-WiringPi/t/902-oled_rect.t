use strict;
use warnings;

use Test::More;
use RPi::WiringPi;

if (! $ENV{RPI_OLED}){
    plan skip_all => "RPI_OLED environment variable not set\n";
}

if (! $ENV{PI_BOARD}){
    $ENV{NO_BOARD} = 1;
    plan skip_all => "Not on a Pi board\n";
}

my $s = RPi::WiringPi->oled('128x64', 0x3C, 0);

# full screen

is $s->rect(0, 0, 128, 64, 1), 1, "rect return ok";
$s->display;

# one pixel border

$s->rect(1, 1, 126, 62, 0);
$s->display;

is $s->rect(0, 0, 128, 64, 1), 1, "rect return ok";
$s->display;

$s->rect(20, 10, 88, 44, 0);
$s->display;

$s->clear;

done_testing();

