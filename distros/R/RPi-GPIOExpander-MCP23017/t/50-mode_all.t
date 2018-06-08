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

done_testing();

