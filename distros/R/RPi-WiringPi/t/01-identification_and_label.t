use strict;
use warnings;
use Test::More;

use RPi::WiringPi;

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
}

my $pi = RPi::WiringPi->new;

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

done_testing();

