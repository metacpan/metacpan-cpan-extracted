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

for my $reg (MCP23017_IODIRA .. MCP23017_IODIRB){
    is $o->register($reg, 0xFF), 0xFF, "pins in bank $reg are INPUT ok";

    if ($reg == MCP23017_IODIRA){
        for my $pin (0 .. 7){
            $o->mode($pin, MCP23017_OUTPUT);
            is
                $o->register_bit($reg, $pin),
                MCP23017_OUTPUT,
                "pin $pin is now in OUTPUT ok";

            $o->write($pin, HIGH);
            is $o->read($pin), HIGH, "pin $pin is HIGH ok";
            $o->write($pin, LOW);
            is $o->read($pin), LOW, "pin $pin is LOW ok";


        }

        is $o->register($reg, 0xFF), 0xFF, "pins in bank $reg back to INPUT ok";
    }

    if ($reg == MCP23017_IODIRB) {
        for my $pin (8..15) {
            $o->mode($pin, MCP23017_OUTPUT);
            is
                $o->register_bit($reg, $pin),
                MCP23017_OUTPUT,
                "pin $pin is now in OUTPUT ok";

            $o->write($pin, HIGH);
            is $o->read($pin), HIGH, "pin $pin is HIGH ok";
            $o->write($pin, LOW);
            is $o->read($pin), LOW, "pin $pin is LOW ok";
        }

        is $o->register($reg, 0xFF), 0xFF, "pins in bank $reg back to INPUT ok";
    }
}

{ # bad params

    is eval { $o->write(5); 1; }, undef, "fails on no state param";
    is eval { $o->write(5, 5); 1; }, undef, "fails on invalid state";
}

done_testing();

