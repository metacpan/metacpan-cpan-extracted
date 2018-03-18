#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::StepperMotor' ) || print "Bail out!\n";
}

diag( "Testing RPi::StepperMotor $RPi::StepperMotor::VERSION, Perl $], $^X" );
