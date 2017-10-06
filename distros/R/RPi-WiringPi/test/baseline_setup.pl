use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;
use RPi::Const qw(:all);

my ($dac_cs_pin, $adc_cs_pin) = (12, 26);
my $adc_shiftreg_in = 2;
my $adc_dac_in = 1;

my $pi = RPi::WiringPi->new;

my $dac = $pi->dac(
    model => 'MCP4922',
    channel => 0,
    cs => $dac_cs_pin
);

my $adc = $pi->adc(
    model => 'MCP3008',
    channel => $adc_cs_pin
);

print "DAC...\n\n";

for (0..4095){
    $dac->set(0, $_);
    if ($_ % 1000 == 0 || $_ == 4095){
        say $adc->percent($adc_dac_in);
    }
}

my $sr = $pi->shift_register(100, 8, 21, 20, 16);

print "\nShift Resgister...\n\n";

my $sr_pin = $pi->pin(101);

$sr_pin->write(HIGH);
say "adc H: " . $adc->percent($adc_shiftreg_in);

$sr_pin->write(LOW);
say "adc L: " . $adc->percent($adc_shiftreg_in);

$sr_pin->write(HIGH);
say "adc H: " . $adc->percent($adc_shiftreg_in);

$sr_pin->write(LOW);
say "adc L: " . $adc->percent($adc_shiftreg_in);

$pi->cleanup;
