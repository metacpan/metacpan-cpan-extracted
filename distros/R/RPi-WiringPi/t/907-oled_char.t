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

for (1..3) {

    $s->clear;
    my $x = $_ * 2;
    my $y = $_ * 2;

    is $s->char($x, $y, 5, $_), 1, "char() return ok";
    $s->display;
}

for (1..3) {

    $s->clear;
    my $x = 50;
    my $y = 15;

    $s->char($x, $y, $_, 4);
    $s->display;
}
#$s->clear;

done_testing();

