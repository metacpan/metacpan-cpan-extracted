use strict;
use warnings;

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::EEPROM::AT24C32' ) || print "Bail out!\n";
}

diag( "Testing RPi::EEPROM::AT24C32 $RPi::EEPROM::AT24C32::VERSION, Perl $], $^X" );
