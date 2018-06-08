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

# writable registers

for my $reg (0x00..0x09, 0x0C..0x0D, 0x14..0x15){
    for my $data (0..255){
        my $ret = $o->register($reg, $data);
        is $ret, $data, "register $reg set to $data ok";
    }
}

# reset the interrupt capture registers

$o->register(MCP23017_INTCAPA);
$o->register(MCP23017_INTCAPB);

{ # non writable: 0x0A-0x0B, 0x0E-0x11

    local $SIG{__WARN__} = sub {};

    for my $reg (0x0A .. 0x0B, 0x0E .. 0x11) {
        is eval {
                $o->register($reg, 0xFF);
                1;
            }, undef, "writing to reg $reg croaks ok";
    }
}
done_testing();

