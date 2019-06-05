use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'RPi::OLED::SSD1306::128_64' ) || print "Bail out!\n";
}

diag( "Testing RPi::OLED::SSD1306::128_64 $RPi::OLED::SSD1306::128_64::VERSION, Perl $], $^X" );

done_testing();
