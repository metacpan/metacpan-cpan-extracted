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

use constant {
    BANK_A => 0,
    BANK_B => 1,
};

my $o = $mod->new(0x20);

{ # set on bank A (0)

    $o->cleanup;

    is
        $o->register(MCP23017_IODIRA, 0xFF),
        0xFF,
        "IODIR pins in bank A are INPUT ok";

    is
        $o->register(MCP23017_IODIRB, 0xFF),
        0xFF,
        "IODIR pins in bank B are INPUT ok";

    $o->mode_bank(BANK_A, MCP23017_OUTPUT);
    is $o->register(MCP23017_IODIRA), 0x00, "pins in bank 0 are OUTPUT ok";

    $o->mode_bank(BANK_B, MCP23017_INPUT);
    is $o->register(MCP23017_IODIRB), 0xFF, "pins in bank 1 are INPUT ok";

    for (0..7){
        my ($pin_a, $pin_b) = ($_, $_ + 8);
        $o->write($pin_a, HIGH);
        is
            $o->read($pin_b),
            HIGH,
            "reading bank A pin $pin_a from bank B $pin_b is HIGH ok";

        $o->write($pin_a, LOW);
        is
            $o->read($pin_b),
            LOW,
            "reading bank A pin $pin_a from bank B $pin_b is LOW ok";
    }
}

{ # set on bank B (1)
    $o->cleanup;

    is
        $o->register(MCP23017_IODIRA, 0xFF),
        0xFF,
        "IODIR pins in bank A are INPUT ok";

    is
        $o->register(MCP23017_IODIRB, 0xFF),
        0xFF,
        "IODIR pins in bank B are INPUT ok";

    $o->mode_bank(BANK_B, MCP23017_OUTPUT);
    is $o->register(MCP23017_IODIRB), 0x00, "pins in bank 1(B) are OUTPUT ok";

    $o->mode_bank(BANK_A, MCP23017_INPUT);
    is $o->register(MCP23017_IODIRA), 0xFF, "pins in bank 0(A) are INPUT ok";

    for (0..7){
        my ($pin_a, $pin_b) = ($_, $_ + 8);
        $o->write($pin_b, HIGH);
        is
            $o->read($pin_a),
            HIGH,
            "reading bank B pin $pin_b from bank A $pin_a is HIGH ok";

        $o->write($pin_b, LOW);
        is
            $o->read($pin_a),
            LOW,
            "reading bank B pin $pin_b from bank A $pin_a is LOW ok";
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
