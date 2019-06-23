use strict;
use warnings;

use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

use lib 't/';

my $mod = 'RPi::WiringPi';

BEGIN {
    if (! $ENV{RPI_ARDUINO}){
        plan skip_all => "RPI_ARUDINO environment variable not set\n";
    }

    if (! $ENV{PI_BOARD}){
        $ENV{NO_BOARD} = 1;
        plan skip_all => "Not on a Pi board\n";
    }
}

$SIG{__DIE__} = sub {};

my $pi = $mod->new;

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

done_testing();

