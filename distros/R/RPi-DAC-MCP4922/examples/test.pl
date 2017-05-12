use warnings;
use strict;
use feature 'say';

use RPi::DAC::MCP4922;
use RPi::ADC::ADS;

my $adc = RPi::ADC::ADS->new;

my $dac = RPi::DAC::MCP4922->new(
    model   => 'MCP4922',
    channel => 1,
    cs      => 18,
    shdn    => 19
);

$dac->set(0, 4095);
$dac->set(1, 4095);

say "init on";
say "0: " . $adc->percent(0) . " %";
say "1: " . $adc->percent(1) . " %";

say "now enabling hw";

$dac->enable_hw;

say "hw enabled on";
say "0: " . $adc->percent(0) . " %";
say "1: " . $adc->percent(1) . " %";

$dac->set(0, 0);
$dac->set(1, 0);

say "zeroed";
say "0: " . $adc->percent(0) . " %";
say "1: " . $adc->percent(1) . " %";

$dac->set(0, 4095);
$dac->set(1, 4095);

say "on";
say "0: " . $adc->percent(0) . " %";
say "1: " . $adc->percent(1) . " %";


say "disable_sw";
$dac->disable_sw(1);
say "0: " . $adc->percent(0) . " %";
say "1: " . $adc->percent(1) . " %";


say "enable_sw";
$dac->enable_sw(1);
say "0: " . $adc->percent(0) . " %";
say "1: " . $adc->percent(1) . " %";

