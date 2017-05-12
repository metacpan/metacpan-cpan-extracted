use warnings;
use strict;
use feature 'say';

use RPi::ADC::ADS;

my $o = RPi::ADC::ADS->new;

my $b = $o->bits;

say $b;
printf("%b\n", $b);

# 0xe00 is the total value of bits 14-12 combined.
# we need the total as this will clear all three bits

$b &= ~0xe00;
printf("%b\n", $b);

# 0xc00 is a value within bits 14-12
# this will set the three bits

$b |= 0xc00;
printf("%b\n", $b);

# 0x03 is the total value of bits 1-0
# use the total value to clear all three bits

$b &= ~0x03;
printf("%b\n", $b);

# 0x02 is a value within bits 1-0
# this will set both appropriately

$b |= 0x02;
printf("%b\n", $b);

