use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;

my $pi = RPi::WiringPi->new;

my $rtc = $pi->i2c(0x68);

# read current sec, min, hr

$DB::single = 1;

my @time = $rtc->read_block(3);

say $_ for @time;

# set a new sec, min, hr

$rtc->write_block([10, 10, 10]);

# re-read

say $_ for $rtc->read_block(3);
