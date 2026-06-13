#!/usr/bin/env perl

use warnings;
use strict;
use feature 'say';

use RPi::ADC::ADS;
use RPi::GPIOExpander::MCP23017;
use RPi::StepperMotor;

for ($ARGV[0], $ARGV[1]){
    if (! $_){
        print "\nUsage:   stepper <cw|ccw> degrees [speed]\n\n";
        print "Example: stepper cw 180 [full]\n\n";
        exit;
    }
}
my $dir = $ARGV[0];
my $deg = $ARGV[1];
my $speed = $ARGV[2] // 'half';

my $expander = RPi::GPIOExpander::MCP23017->new(0x21);

my $s = RPi::StepperMotor->new(
    pins => [0, 1, 2, 3],
    expander => $expander,
    delay => 0.0,
    speed => $speed
);

my $adc = RPi::ADC::ADS->new(addr => 0x49);

if ($dir eq 'cw'){
    $s->cw($deg);
}
else {
    $s->ccw($deg);
}

say "c: " . $adc->raw(1);
say "r: " . $adc->raw(0);
say "l: " . $adc->raw(2);

$expander->cleanup;
$s->cleanup;
