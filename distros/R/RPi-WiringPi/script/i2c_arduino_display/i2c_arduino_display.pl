#!/usr/bin/env perl

use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;

use constant {
    PROCESS_SYSINFO => 35,
    ENABLE_DISPLAY => 1,
    DISABLE_DISPLAY => 0
};

my $pi = RPi::WiringPi->new;

my $arduino = $pi->i2c(0x05);

while (1){
    my $result = $arduino->write_block(
        [
            int $pi->cpu_percent,
            int $pi->mem_percent,
            int $pi->core_temp('f'),
        ], 
        35
    );

    # disable/enable the display

    # $arduino->write_byte(0x00, DISABLE_DISPLAY);
    # sleep 1;
    #$arduino->write(0x00, ENABLE_DISPLAY);
    # sleep 1;  
    sleep 1;
}

$pi->cleanup;

