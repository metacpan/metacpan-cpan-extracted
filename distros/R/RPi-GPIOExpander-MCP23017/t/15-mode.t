use warnings;
use strict;
use feature 'say';

use Test::More;

BEGIN {
    if (!$ENV{RPI_MCP23017}) {
        plan(skip_all => "RPI_MCP23017 environment variable not set");
    }

    if (!$ENV{RPI_SUBMODULE_TESTING}) {
        plan(skip_all => "RPI_SUBMODULE_TESTING environment variable not set");
    }
}

use RPi::Const qw(:all);
use RPi::GPIOExpander::MCP23017;

my $mod = 'RPi::GPIOExpander::MCP23017';

my $o = $mod->new(0x20);

for my $reg (MCP23017_IODIRA .. MCP23017_IODIRB){
    is $o->register($reg, 0xFF), 0xFF, "pins in bank $reg are INPUT ok";

    if ($reg == MCP23017_IODIRA){
        for my $pin (0 .. 7) {
            $o->mode($pin, MCP23017_OUTPUT);
            is
                $o->register_bit($reg, $pin),
                MCP23017_OUTPUT,
                "pin $pin is now in OUTPUT ok";
        }
        is $o->register($reg, 0xFF), 0xFF, "pins in bank $reg back to INPUT ok";
    }


    if ($reg == MCP23017_IODIRB){
        for my $pin (8..15) {
            $o->mode($pin, MCP23017_OUTPUT);
            is
                $o->register_bit($reg, $pin),
                MCP23017_OUTPUT,
                "pin $pin is now in OUTPUT ok";
        }
        is $o->register($reg, 0xFF), 0xFF, "pins in bank $reg back to INPUT ok";
    }
}

{ # get

    $o->cleanup;

    for (0..15){
        is $o->mode($_), MCP23017_INPUT, "pin $_ INPUT ok";
        $o->mode($_, MCP23017_OUTPUT);

        is $o->mode($_), MCP23017_OUTPUT, "pin $_ OUTPUT ok";

        $o->mode($_, MCP23017_INPUT);
        is $o->mode($_), MCP23017_INPUT, "pin $_ back to INPUT ok";
    }
}
done_testing();

