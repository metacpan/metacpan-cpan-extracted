use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;

my $pi = RPi::WiringPi->new;

my $pin = $pi->pin(18);

say $pin->mode;
say $pin->read;

say $pi->registered_pins;

$pin->mode(1);
$pin->write(1);

say $pin->mode;
say $pin->read;

$pi->unregister_pin($pin);

say $pin->mode;
say $pin->read;

