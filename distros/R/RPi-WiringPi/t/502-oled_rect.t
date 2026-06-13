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

my $pi = RPi::WiringPi->new(label => 't/502-oled_rect.t', shm_key => 'rpit');
my $s = $pi->oled('128x64', 0x3C, 0);

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

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

