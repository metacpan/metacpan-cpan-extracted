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

is $s->rect(0, 0, 128, 64, 1), 1, "rect return ok";
$s->display;

is $s->dim(1), 1, "dim() return ok";

sleep 1;

$s->dim(0);

$s->clear;

done_testing();

