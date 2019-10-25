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

if (! $ENV{RPI_SUBMODULE_TESTING}){
    plan(skip_all => "RPI_SUBMODULE_TESTING environment variable not set");
}

my $mod = 'RPi::GPIOExpander::MCP23017';

my $o = $mod->new(0x20);

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

done_testing();

