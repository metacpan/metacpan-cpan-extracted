use strict;
use warnings;

use lib 't/';

use RPiTest;
use Test::More;
use RPi::Const;
use RPi::WiringPi;

if (! $ENV{RPI_OLED}){
    plan skip_all => "RPI_OLED environment variable not set\n";
}

rpi_running_test(__FILE__);

rpi_oled_unavailable();
is rpi_oled_available(), 0, "oled unavailable for use ok";

my $pi = RPi::WiringPi->new(label => 't/500-oled_new.t', shm_key => 'rpit');

my $s = $pi->oled('128x64', 0x3C, 0);

is ref $s, 'RPi::OLED::SSD1306::128_64', "oled() returns an object of proper class";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

