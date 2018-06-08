use warnings;
use strict;
use feature 'say';

use RPi::Const qw(:all);
use RPi::GPIOExpander::MCP23017;

my $mcp23017_i2c_addr = 0x20;

my $exp = RPi::GPIOExpander::MCP23017->new($mcp_i2c_addr);

# pins are INPUT by default. Turn the first pin to OUTPUT

$exp->mode(0, 0); # or MCP23017_OUTPUT if using RPi::Const

# turn the pin on (HIGH)

$exp->write(0, 1); # or HIGH

# turn the first bank (0) of pins (0-7) to OUTPUT, and make them live (HIGH)

$exp->mode_bank(0, 0);  # bank A, OUTPUT
$exp->write_bank(0, 1); # bank A, HIGH

# enable internal pullup resistors on the entire bank A (0)

$exp->pullup_bank(0, 1); # bank A, pullup enabled

# put all 16 pins as OUTPUT, and put them on (HIGH)

$exp->mode_all(0);  # or OUTPUT
$exp->write_all(1); # or HIGH

# cleanup all pins and reset them to default before exiting your program

$exp->cleanup;



