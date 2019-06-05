use strict;
use warnings;

use RPi::OLED::SSD1306::128_64;

my $oled = RPi::OLED::SSD1306::128_64->new(0x3c);

$oled->string("blah blah", 1);
