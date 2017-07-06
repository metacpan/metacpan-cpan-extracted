use warnings;
use strict;

# writes a 16-bit word to the Arduino

# LSB is read first, then the MSB

use RPi::I2C;

my $arduino_addr = 0x04;

my $arduino = RPi::I2C->new($arduino_addr);

my $x = $arduino->write_word(1024, 0x01);

sub delay {
    die "delay() needs a number\n" if ! @_;
    return select(undef, undef, undef, shift);
}
