use warnings;
use strict;

# writes an 8-bit byte to the Arduino

# LSB is read first, then the MSB

use RPi::I2C;

my $arduino_addr = 0x04;

my $arduino = RPi::I2C->new($arduino_addr);

$arduino->write(25);

# read the eeprom data back

my @eeprom = $arduino->read_block(4, 99);

print "eeprom: $eeprom[0]\n";

sub delay {
    die "delay() needs a number\n" if ! @_;
    return select(undef, undef, undef, shift);
}
