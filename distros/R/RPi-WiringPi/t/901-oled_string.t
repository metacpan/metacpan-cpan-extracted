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

for (1..5) {
    $s->clear;
    my $size_r = $s->text_size($_);
    is $size_r, 1, "return from text_size($_) ok";
    my $string_r = $s->string("hello", 1);
    is $string_r, 1, "return from string() ok";

}
$s->clear;

done_testing();

