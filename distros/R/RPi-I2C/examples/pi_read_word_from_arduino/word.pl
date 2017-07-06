use warnings;
use strict;

# read word from Arduino

# NOTE that the Arduino has LSB first, so the
# bytes need to be swapped.

# Also, the Arduino can only send a single byte
# at a time, so it's not trustworthy to be testing
# read_word() on

use RPi::I2C;

my $arduino_addr = 0x04;

my $arduino = RPi::I2C->new($arduino_addr);

for (0..10){
    my $d = $arduino->read_word(0x05);
    print "$d\n";
    delay(0.5);
}

sub delay {
    die "delay() needs a number\n" if ! @_;
    return select(undef, undef, undef, shift);
}
