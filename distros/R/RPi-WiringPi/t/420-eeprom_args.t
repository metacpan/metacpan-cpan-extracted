use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use Test::More;

BEGIN {
    if (! $ENV{RPI_EEPROM}){
        plan skip_all => "RPI_EEPROM environment variable not set\n";
    }
}

rpi_running_test(__FILE__);

my $pi = RPi::WiringPi->new(label => 't/420-eeprom_args.t', shm_key => 'rpit');
my $e = $pi->eeprom;

is ref $e, 'RPi::EEPROM::AT24C32', "object is of proper class";
is $e->{address}, 0x57, "default i2c address ok";
is $e->{device}, '/dev/i2c-1', "default i2c device ok";
is $e->{delay}, 1, "default delay ok";
is $e->{fd} > 0, 1, "file descriptor initialised and set ok";

$pi->cleanup;

rpi_check_pin_status();
#rpi_metadata_clean();

done_testing();

