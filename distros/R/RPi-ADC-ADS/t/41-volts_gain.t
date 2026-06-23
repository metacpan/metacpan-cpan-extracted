use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

# V6: volts() scales by the programmed PGA full-scale range, not a constant
# 4.096V. So a fixed input reads the same voltage at any gain - the raw code
# changes with gain, but the scaled voltage does not. Gains 0 and 1 are
# high-impedance (negligible PGA loading), so they agree closely; before the
# fix the two differed by the FSR ratio. Needs a stable, non-trivial voltage on
# channel 0.

if (! $ENV{PI_TEST}){
    plan skip_all => "PI_TEST env var not set";
}

my $adc = RPi::ADC::ADS->new(samples => 50);

$adc->gain(1);
my $v1 = $adc->volts(0);

if ($v1 < 0.1){
    plan skip_all =>
        "no usable input on channel 0 (gain-1 reads ${v1}V); cannot test gain scaling";
}

$adc->gain(0);
my $v0 = $adc->volts(0);

my $dev = abs($v0 - $v1) / $v1;

cmp_ok $dev, '<', 0.12, sprintf(
    "volts is gain-consistent: gain0=%.4fV gain1=%.4fV (%.1f%% apart)",
    $v0, $v1, $dev * 100,
);

done_testing();
