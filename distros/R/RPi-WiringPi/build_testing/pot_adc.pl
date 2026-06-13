use warnings;
use strict;

# testing for use in hard test prototype for
# RPi::WiringPi

use 5.10.0;

use RPi::WiringPi;
use RPi::Const qw(:all);

use constant {
    DPOT_CS => 13,
    DPOT_CH => 0,
    ADC_CH => 1,
};

my $pi = RPi::WiringPi->new;

my $adc = $pi->adc;
my $pot = $pi->dpot(DPOT_CS, DPOT_CH);

for (0..255){
    $pot->set($_);
    say "pot set to $_: " . $adc->percent(ADC_CH);
}
