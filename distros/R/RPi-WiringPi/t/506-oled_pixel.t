use strict;
use warnings;

use lib 't/';

use RPiTest;
use Test::More;
use RPi::WiringPi;

if (! $ENV{RPI_OLED}){
    plan skip_all => "RPI_OLED environment variable not set\n";
}

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/506-oled_pixel.t', shm_key => 'rpit');
my $s = $pi->oled('128x64', 0x3C, 0);

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

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

