#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::WiringPi::Constant' ) || print "Bail out!\n";
}

diag( "Testing RPi::WiringPi::Constant $RPi::WiringPi::Constant::VERSION, Perl $], $^X" );
