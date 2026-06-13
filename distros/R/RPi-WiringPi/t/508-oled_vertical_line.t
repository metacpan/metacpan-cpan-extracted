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

my $pi = RPi::WiringPi->new(label => 't/508-oled_vertical_line.t', shm_key => 'rpit');
my $s = $pi->oled('128x64', 0x3C, 0);

is $s->vertical_line(64, 0, 64), 1, "vertical_line() return ok";
$s->display;

$s->clear;

$pi->cleanup;

rpi_check_pin_status();
rpi_metadata_clean();

done_testing();

