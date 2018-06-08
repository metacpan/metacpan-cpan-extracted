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

use constant {
    BANK_A => 0,
    BANK_B => 1,
};

$o->cleanup;

{ # 0 OUTPUT/HIGH, 1 INPUT/read
    is
        $o->register(MCP23017_IODIRA, 0xFF),
        0xFF,
        "IODIR pins in bank A are INPUT ok";

    is
        $o->register(MCP23017_IODIRB, 0xFF),
        0xFF,
        "IODIR pins in bank B are INPUT ok";

    $o->mode_bank(BANK_A, MCP23017_OUTPUT);

    is
        $o->register(MCP23017_IODIRA, MCP23017_OUTPUT),
        MCP23017_OUTPUT,
        "pins in bank 0 are OUTPUT ok";

    $o->mode_bank(BANK_B, MCP23017_INPUT);

    is
        $o->register(MCP23017_IODIRB),
        0xFF,
        "pins in bank 1 are INPUT ok";

    $o->write_bank(BANK_A, HIGH);

    is $o->register(MCP23017_GPIOA), 0xFF, "pins in bank 0 are HIGH ok";

    for (0..7){
        my ($pin_a, $pin_b) = ($_, $_ + 8);
        is
            $o->read($pin_b),
            HIGH,
            "reading bank A pin $pin_a from bank B $pin_b is HIGH ok";
    }

    $o->write_bank(BANK_A, LOW);
    is $o->register(MCP23017_GPIOA), LOW, "pins in bank 0 are LOW ok";

    for (0..7){
        my ($pin_a, $pin_b) = ($_, $_ + 8);
        is
            $o->read($pin_b),
            LOW,
            "reading bank A pin $pin_a from bank B $pin_b is LOW ok";
    }
}

{ # 0 INPUT/read, 1 OUTPUT/HIGH

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
    is $o->register(MCP23017_IODIRB), 0, "pins in bank 1(B) are OUTPUT ok";

    $o->mode_bank(BANK_A, MCP23017_INPUT);
    is $o->register(MCP23017_IODIRA), 0xFF, "pins in bank 0(A) are INPUT ok";

    $o->write_bank(BANK_B, HIGH);
    is $o->register(MCP23017_GPIOB), 255, "pins in bank 1(B) are HIGH ok";

    for (0..7){
        my ($pin_a, $pin_b) = ($_, $_ + 8);
        is
            $o->read($pin_a),
            HIGH,
            "reading bank B pin $pin_b from bank A $pin_a is HIGH ok";
    }

    $o->write_bank(BANK_B, LOW);
    is $o->register(MCP23017_GPIOB), 0, "pins in bank 1 are LOW ok";

    for (0..7){
        my ($pin_a, $pin_b) = ($_, $_ + 8);
        is
            $o->read($pin_a),
            LOW,
            "reading bank B pin $pin_b from bank A $pin_a is LOW ok";
    }

    $o->cleanup;
}

{ # bad params

    is eval { $o->write_bank(5); 1; }, undef, "fails on invalid bank";
    is eval { $o->write_bank(BANK_B); 1; }, undef, "fails on missing state";
    is eval { $o->write_bank(BANK_A, 5); 1; }, undef, "fails on invalid state";

}

done_testing();
