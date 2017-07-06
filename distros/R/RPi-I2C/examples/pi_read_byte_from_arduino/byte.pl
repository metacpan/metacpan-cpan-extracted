use warnings;
use strict;

# does a single byte basic read() from an Arduino
# and prints out whatever is returned

# 5

use RPi::I2C;

my $arduino_addr = 0x04;

my $arduino = RPi::I2C->new($arduino_addr);

my $d = $arduino->read_byte(0x05);
print "$d\n";

sub delay {
    die "delay() needs a number\n" if ! @_;
    return select(undef, undef, undef, shift);
}
