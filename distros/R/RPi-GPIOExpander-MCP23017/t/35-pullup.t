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

use constant {
    BANK_A => 0,
    BANK_B => 1,
};

my $mod = 'RPi::GPIOExpander::MCP23017';

my $o = $mod->new(0x20);

for my $reg (MCP23017_GPPUA .. MCP23017_GPPUB){
    is $o->register($reg, 0x00), 0x00, "pullups in bank $reg are off ok";

    if ($reg == MCP23017_GPPUA){
        for my $pin (0 .. 7) {
            $o->pullup($pin, HIGH);
            is
                $o->register_bit($reg, $pin),
                HIGH,
                "pin $pin pullup is now on";

            $o->pullup($pin, LOW);
            is
                $o->register_bit($reg, $pin),
                LOW,
                "pin $pin pullup is now off";
        }
        is $o->register($reg, 0x00), 0x00, "pullups in bank $reg to off ok";
    }


    if ($reg == MCP23017_GPPUB){
        for my $pin (8..15) {
            $o->pullup($pin, HIGH);
            is
                $o->register_bit($reg, $pin),
                HIGH,
                "$pin pullup is now on ok";

            $o->pullup($pin, LOW);
            is
                $o->register_bit($reg, $pin),
                LOW,
                "pin $pin pullup is now off";
        }
        is $o->register($reg, 0x00), 0x00, "pullups in bank $reg to off ok";
    }
}

{ # get

    $o->cleanup;

    for (0..15){
        is $o->pullup($_), LOW, "pin $_ pullup off ok";

        $o->pullup($_, HIGH);
        is $o->pullup($_), HIGH, "pin $_ pullup on ok";

        $o->pullup($_, LOW);
        is $o->pullup($_), LOW, "pin $_ pullup back to off ok";
    }

    $o->cleanup;
}

{ # bad params

    is eval { $o->mode_bank(5); 1; }, undef, "fails on invalid bank";
    is eval { $o->mode_bank(BANK_A, 5); 1; }, undef, "fails on invalid state";

}
{ # return if no state sent

    is $o->mode_bank(BANK_A), 0xFF, "returns bank register if no state sent";
}

done_testing();

