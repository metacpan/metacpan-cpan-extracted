use warnings;
use strict;

use RPi::WiringPi;

my $pi = RPi::WiringPi->new;

my $sm = $pi->stepper_motor(pins => [12, 16, 20, 21]);

while (1){
    $sm->ccw(180);
    $sm->cw(180);
}
