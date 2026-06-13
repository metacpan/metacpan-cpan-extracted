use strict;
use warnings;
use Test::More;

use lib 't/';
use RPi::WiringPi;
use RPiTest;

my $pi = RPi::WiringPi->new(
    shm_key => 'rpit'
);

rpi_running_test(__FILE__);

my $ok = eval {
    $pi->pwr_led(1); # pwr led OFF
    $pi->io_led(1);  # io led ON
    sleep 2;
    $pi->io_led();  # io led restored
    $pi->pwr_led(); # power led restored
    1;
};

is $ok, 1, "pwr_led() and io_led() sudo ok";

is $pi->label, '', "label() without initial param empty string ok";
is $pi->label('hello'), 'hello', "label() with param ok";
is $pi->label, 'hello', "label() w/o param ok after setting it previously";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

