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

done_testing();

