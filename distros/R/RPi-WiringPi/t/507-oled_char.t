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

my $pi = RPi::WiringPi->new(label => 't/507-oled_char.t', shm_key => 'rpit');
my $s = $pi->oled('128x64', 0x3C, 0);

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

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

