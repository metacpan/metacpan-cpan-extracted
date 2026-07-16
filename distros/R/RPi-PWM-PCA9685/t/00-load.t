#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::PWM::PCA9685' ) || print "Bail out!\n";
}

diag( "Testing RPi::PWM::PCA9685 $RPi::PWM::PCA9685::VERSION, Perl $], $^X" );
