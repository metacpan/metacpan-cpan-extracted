# this test ensures that if RPi::WiringPi sets a setup mode, that
# this software will use that mode and not crash

# dht11 => pin 1 (wpi)
# led => pin 29 (wpi)

use warnings;
use strict;
use feature 'say';

use RPi::DHT11;
use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);

my $pi = RPi::WiringPi->new(setup => 'wpi');
my $e = RPi::DHT11->new(1);

say $e->temp;

my $pin = $pi->pin(29);
$pin->mode(OUTPUT);
$pin->write(HIGH);

sleep 1;
$pi->cleanup;
