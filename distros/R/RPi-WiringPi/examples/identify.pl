use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;

my $pi = RPi::WiringPi->new;

$pi->pwr_led(1); # pwr led OFF
$pi->io_led(1);  # io led ON
sleep 2;
$pi->io_led();  # io led restored
$pi->pwr_led(); # power led restored

say $pi->label;

$pi->label('label_test');

say $pi->label;
