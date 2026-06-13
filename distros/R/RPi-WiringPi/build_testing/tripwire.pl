use warnings;
use strict;
use feature 'say';

use RPi::Const qw(:all);
use RPi::WiringPi;

my $continue = 1;

$SIG{INT} = sub {
    $continue = 0;
};

my $pi = RPi::WiringPi->new;

my $buzz_pin = $pi->pin(21);
$buzz_pin->mode(OUTPUT);

my $adc = $pi->adc;

while ($continue){
    my $input = $adc->raw(0);

    if ($input > 100){
        $buzz_pin->write(HIGH);
    }
    else {
        $buzz_pin->write(LOW) if $buzz_pin->read == HIGH;
    }

    say "photoresistor output: $input";
}

$pi->cleanup;
