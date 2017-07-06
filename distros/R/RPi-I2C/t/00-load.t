use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::I2C' ) || print "Bail out!\n";
}

diag( "Testing RPi::I2C $RPi::I2C::VERSION, Perl $], $^X" );
