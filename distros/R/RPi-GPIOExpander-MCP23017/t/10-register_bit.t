use warnings;
use strict;
use feature 'say';

use RPi::Const qw(:all);
use RPi::GPIOExpander::MCP23017;
use Test::More;

if (! $ENV{RPI_MCP23017}){
    plan(skip_all => "Skipping: RPI_MCP23017 environment variable not set");
}

my $mod = 'RPi::GPIOExpander::MCP23017';

my $o = $mod->new(0x20);

my @bits = (1, 2, 4, 8, 16, 32, 64, 128);

for my $reg (0x00..0x09, 0x0C..0x0D, 0x14..0x15){
    # skip read-only registers

    for my $bit (0..$#bits){
        is
            $o->register($reg, $bits[$bit]),
            $bits[$bit],
            "bit '$bit' in reg '$reg' set to $bits[$bit] ok";

        for (0..$bit -1){
            is $o->register_bit($reg, $_), 0, "bit '$_' in reg '$reg' is off ok";
        }
        is $o->register_bit($reg, $bit), 1, "bit '$bit' in reg '$reg' is on ok";
    }
}

# reset the interrupt capture registers

$o->register(MCP23017_INTCAPA);
$o->register(MCP23017_INTCAPB);

done_testing();

