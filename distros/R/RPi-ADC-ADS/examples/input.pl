use warnings;
use strict;
use feature 'say';

use RPi::ADC::ADS;

my $o = RPi::ADC::ADS->new;

printf("%b\n", $o->bits);

say $o->volts(3);
