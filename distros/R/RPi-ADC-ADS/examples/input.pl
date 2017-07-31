use warnings;
use strict;
use feature 'say';

use RPi::ADC::ADS;

my $c = 1;

$SIG{INT} = sub {
    $c = 0;
};

my $o = RPi::ADC::ADS->new;

while ($c){
    printf("%b\n", $o->bits);
    say $o->volts(0) ." v";
    say $o->percent(0) . " %";
    sleep 1;
}
