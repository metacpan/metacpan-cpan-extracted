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

my $pi = RPi::WiringPi->new(label => 't/503-oled_dim.t', shm_key => 'rpit');
my $s = $pi->oled('128x64', 0x3C, 0);

is $s->rect(0, 0, 128, 64, 1), 1, "rect return ok";
$s->display;

is $s->dim(1), 1, "dim() return ok";

sleep 1;

$s->dim(0);

$s->clear;

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

