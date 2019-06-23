use warnings;
use strict;

use RPi::WiringPi;

my $pi = RPi::WiringPi->new;

$pi->shift_register(100, 3, 5, 6, 13);

for (0..1){
    my $pin = $pi->pin(100 + $_);
    $pin->write(1);
    print "pin 100 + $_\n";
    sleep 1;
    $pin->write(0);
}

