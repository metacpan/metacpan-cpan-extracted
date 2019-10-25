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

$o->cleanup;

sleep 10;

for (0x00..0x15){
    if ($_ == MCP23017_IODIRA || $_ == MCP23017_IODIRB){
        is $o->register($_), 0xFF, "register $_ back to 0xFF ok";
    }
    else {
        is $o->register($_), 0x00, "register $_ back to 0x00 ok";
    }
}

done_testing();

