use strict;
use warnings;
use Test::More;

use RPi::OLED::SSD1306::128_64;

# Live on-device test: requires an SSD1306 128x64 OLED on the I2C bus (0x3C).
# Enable with RPI_OLED=1. Skipped otherwise, so it stays inert on CPAN testers
# and machines without the panel.
plan skip_all => "RPI_OLED not set (needs an SSD1306 OLED on I2C 0x3C)"
    if ! $ENV{RPI_OLED};

my $mod  = 'RPi::OLED::SSD1306::128_64';
my $oled = $mod->new;

isa_ok $oled, $mod;

is $oled->clear, 1, 'clear(): ok on the live panel';
is $oled->text_size(2), 1, 'text_size(2): ok';
is $oled->string("RPi::OLED", 1), 1, 'string(): drawn and displayed';
is $oled->rect(0, 40, 128, 20), 1, 'rect(): buffered';
is $oled->pixel(64, 32), 1, 'pixel(): buffered';
is $oled->display, 1, 'display(): pushed the buffer to the panel';

is $oled->invert_display(1), 1, 'invert_display(1): ok';
select(undef, undef, undef, 0.3);
is $oled->invert_display(0), 1, 'invert_display(0): ok';

is $oled->dim(1), 1, 'dim(1): ok';
is $oled->dim(0), 1, 'dim(0): ok';

is $oled->clear, 1, 'clear(): final wipe';

done_testing();
