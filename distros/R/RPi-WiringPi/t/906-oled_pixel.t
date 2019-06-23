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

for (1..5){
    my $x = int(rand(128));
    my $y = int(rand(64));

    print "$x, $y\n";
    is $s->pixel($x, $y, 1), 1, "pixel() return ok";
    $s->display;
}

for (1..100){
    my $x = int(rand(128));
    my $y = int(rand(64));

    print "$x, $y\n";
    $s->pixel($x, $y, 1);
}

$s->display;

$s->clear;

done_testing();

