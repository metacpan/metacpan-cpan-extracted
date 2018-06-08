use strict;
use warnings;
use Test::More;

BEGIN {

    if (! $ENV{RPI_MCP23017}){
        plan(skip_all => "Skipping: RPI_MCP23017 environment variable not set");
    }

    use_ok( 'RPi::GPIOExpander::MCP23017' ) || print "Bail out!\n";
}

use RPi::Const qw(:all);
use RPi::WiringPi;

use constant {
    BANK_A => 0,
    BANK_B => 1,
};

my $pi = RPi::WiringPi->new(fatal_exit => 0);
my $o = $pi->expander(0x20);

{ # registers.t

    # writable registers

    for my $reg (0x00 .. 0x09, 0x0C .. 0x0D, 0x14 .. 0x15) {
        for my $data (0 .. 255) {
            my $ret = $o->register($reg, $data);
            is $ret, $data, "register $reg set to $data ok";
        }
    }

    # reset the interrupt capture registers

    $o->register(MCP23017_INTCAPA);
    $o->register(MCP23017_INTCAPB);

    {
        # non writable: 0x0A-0x0B, 0x0E-0x11

        local $SIG{__WARN__} = sub {};

        for my $reg (0x0A .. 0x0B, 0x0E .. 0x11) {
            is eval {
                    $o->register($reg, 0xFF);
                    1;
                }, undef, "writing to reg $reg croaks ok";
        }
    }
}

{ # register_bit.t

    my @bits = (1, 2, 4, 8, 16, 32, 64, 128);

    for my $reg (0x00 .. 0x09, 0x0C .. 0x0D, 0x14 .. 0x15) {
        # skip read-only registers

        for my $bit (0 .. $#bits) {
            is
                $o->register($reg, $bits[$bit]),
                $bits[$bit],
                "bit '$bit' in reg '$reg' set to $bits[$bit] ok";

            for (0 .. $bit - 1) {
                is $o->register_bit($reg, $_), 0,
                    "bit '$_' in reg '$reg' is off ok";
            }
            is $o->register_bit($reg, $bit), 1,
                "bit '$bit' in reg '$reg' is on ok";
        }
    }

    # reset the interrupt capture registers

    $o->register(MCP23017_INTCAPA);
    $o->register(MCP23017_INTCAPB);
}

{
    # mode.t

    for my $reg (MCP23017_IODIRA .. MCP23017_IODIRB) {
        is $o->register($reg, 0xFF), 0xFF, "pins in bank $reg are INPUT ok";

        if ($reg == MCP23017_IODIRA) {
            for my $pin (0 .. 7) {
                $o->mode($pin, MCP23017_OUTPUT);
                is
                    $o->register_bit($reg, $pin),
                    MCP23017_OUTPUT,
                    "pin $pin is now in OUTPUT ok";
            }
            is $o->register($reg, 0xFF), 0xFF,
                "pins in bank $reg back to INPUT ok";
        }

        if ($reg == MCP23017_IODIRB) {
            for my $pin (8 .. 15) {
                $o->mode($pin, MCP23017_OUTPUT);
                is
                    $o->register_bit($reg, $pin),
                    MCP23017_OUTPUT,
                    "pin $pin is now in OUTPUT ok";
            }
            is $o->register($reg, 0xFF), 0xFF,
                "pins in bank $reg back to INPUT ok";
        }
    }

    {
        # get

        $o->cleanup;

        for (0 .. 15) {
            is $o->mode($_), MCP23017_INPUT, "pin $_ INPUT ok";
            $o->mode($_, MCP23017_OUTPUT);

            is $o->mode($_), MCP23017_OUTPUT, "pin $_ OUTPUT ok";

            $o->mode($_, MCP23017_INPUT);
            is $o->mode($_), MCP23017_INPUT, "pin $_ back to INPUT ok";
        }
    }
}

{ # write.t

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

            is
                $o->register($reg, 0xFF),
                0xFF,
                "pins in bank $reg back to INPUT ok";
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

            is
                $o->register($reg, 0xFF),
                0xFF,
                "pins in bank $reg back to INPUT ok";
        }
    }

    { # bad params

        is eval { $o->write(5); 1; }, undef, "fails on no state param";
        is eval { $o->write(5, 5); 1; }, undef, "fails on invalid state";
    }
}

{ # bank_mode.t

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

}

{ # bank_write.t

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
        is
            eval { $o->write_bank(BANK_A, 5); 1; },
            undef,
            "fails on invalid state";

    }
}

{ # pullup.t

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

}

{ # pullup_bank.t

     for my $reg (MCP23017_GPPUA .. MCP23017_GPPUB){
        is $o->register($reg, 0x00), 0x00, "pullups in bank $reg are off ok";

        if ($reg == MCP23017_GPPUA){
            for (0x00..0xFF){
                is $o->register($reg, $_), $_, "bank A pullup register set to $_";
            }
            is $o->register($reg, 0x00), 0x00, "pullups in bank $reg to off ok";
        }

        if ($reg == MCP23017_GPPUB){
            for (0x00..0xFF){
                is $o->register($reg, $_), $_, "bank B pullup register set to $_";
            }
            is $o->register($reg, 0x00), 0x00, "pullups in bank $reg to off ok";
        }
    }

    { # bad params

        is eval { $o->pullup_bank(5); 1; }, undef, "fails on invalid bank";
        is eval { $o->pullup_bank(BANK_A, 5); 1; }, undef, "fails on invalid state";

    }
    { # return if no state sent

        is $o->mode_bank(BANK_A), 0xFF, "returns bank register if no state sent";
    }
}

{ # mode_all.t

    my @regs = (MCP23017_IODIRA .. MCP23017_IODIRB);

    { # set/unset
        for (@regs){
            is $o->register($_), 0xFF, "register $_ set to 0xFF ok";
        }

        $o->mode_all(MCP23017_OUTPUT);

        for (@regs){
            is $o->register($_), 0x00, "register $_ set to 0x00 ok";
        }

        $o->mode_all(MCP23017_INPUT);

        for (@regs){
            is $o->register($_), 0xFF, "register $_ set back to default 0xFF ok";
        }
    }

    { # bad params
        is eval { $o->mode_all(5); 1; }, undef, "fails on invalid mode";
    }
}

{ # write_all.t

     my @regs = (MCP23017_GPIOA .. MCP23017_GPIOB);

    { # set/unset

        $o->mode_all(MCP23017_OUTPUT);
        for (MCP23017_IODIRA .. MCP23017_IODIRB){
            is $o->register($_), 0x00, "IODIR register $_ set to OUTPUT ok";
        }

        $o->write_all(HIGH);

        for (@regs){
            is $o->register($_), 0xFF, "register $_ set to 0xFF (all HIGH) ok";
        }

        $o->write_all(LOW);

        for (@regs){
            is $o->register($_), 0x00, "register $_ set to 0x00 (all LOW) ok";
        }

        $o->mode_all(MCP23017_INPUT);
        for (MCP23017_IODIRA .. MCP23017_IODIRB){
            is $o->register($_), 0xFF, "IODIR register $_ set back to INPUT ok";
        }
    }

    { # bad params
        is eval { $o->write_all(5); 1; }, undef, "fails on invalid state";
    }
}

{ # pullup_all.t

    my @regs = (MCP23017_GPPUA .. MCP23017_GPPUB);

    { # set/unset

        $o->mode_all(MCP23017_OUTPUT);
        for (MCP23017_IODIRA .. MCP23017_IODIRB){
            is $o->register($_), 0x00, "IODIR register $_ set to OUTPUT ok";
        }

        $o->pullup_all(HIGH);

        for (@regs){
            is $o->register($_), 0xFF, "register $_ set to 0xFF (all HIGH) ok";
        }

        $o->pullup_all(LOW);

        for (@regs){
            is $o->register($_), 0x00, "register $_ set to 0x00 (all LOW) ok";
        }

        $o->mode_all(MCP23017_INPUT);
        for (MCP23017_IODIRA .. MCP23017_IODIRB){
            is $o->register($_), 0xFF, "IODIR register $_ set back to INPUT ok";
        }
    }

    { # bad params
        is eval { $o->pullup_all(5); 1; }, undef, "fails on invalid state";
    }
}

{ # default_registers.t

    # let GPIO state registers reset after toggling pullups

    sleep 3;

    for (0x00..0x15){
        if ($_ == MCP23017_IODIRA || $_ == MCP23017_IODIRB){
            is $o->register($_), 0xFF, "register $_ back to 0xFF ok";
        }
        else {
            is $o->register($_), 0x00, "register $_ back to 0x00 ok";
        }
    }
}

done_testing();
