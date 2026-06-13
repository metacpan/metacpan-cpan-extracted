use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

BEGIN {
    if (! $ENV{RPI_ARDUINO}){
        plan skip_all => "RPI_ARDUINO environment variable not set\n";
    }
}

$SIG{__DIE__} = sub {};

my $pi = $mod->new(fatal_exit => 0, label => 't/300-i2c_exceptions.t', shm_key => 'rpit');

{ # catch device not found
    is eval { $pi->i2c(0x99); 1; }, undef, "I2C init dies if device not found";
    like $@, qr/I2C device at address/, "...and error message is sane";
}

{ # catch panic if device isn't available (stevieb9/rpi-i2c#2)

    $ENV{I2C_TESTING} = 1; # disable exit() if device not found

    my $addr = 0x99;
    my $dev = $pi->i2c($addr);

    is
        eval { $dev->read_block(2, 80); 1; },
        undef,
        "I2C read_block() croaks if the device has been detached";

    like $@, qr/has invalid return/, "...and error msg is sane";
    
    is
        eval { $dev->read_block(2, 80); 1; },
        undef,
        "I2C read_block() croaks if speed may be the issue";

    like $@, qr/speed set correctly/, "...speed error msg is sane";
}

$ENV{I2C_TESTING} = 0;

$pi->cleanup;
rpi_check_pin_status();
# rpi_metadata_clean();

done_testing();

