use warnings;
use strict;

use Mock::Sub;
use Test::More;

use RPi::DigiPot::MCP4XXXX;

if (! $ENV{PI_BOARD}){
    plan skip_all => "not a Pi board (env PI_BOARD)";
    exit;
}

my $mod = 'RPi::DigiPot::MCP4XXXX';

my $m = Mock::Sub->new;
my $wpi_setup = $m->mock("${mod}::wiringPiSetupGpio");
my $wpi_mode = $m->mock("${mod}::pinMode");
my $wpi_write = $m->mock("${mod}::digitalWrite");

is $wpi_setup->mocked_state, 1, "wiringPiSetupGpio() mocked ok";
is $wpi_mode->mocked_state, 1, "pinMode() mocked ok";
is $wpi_write->mocked_state, 1, "digitalWrite() mocked ok";

{ # bad
    
    my $ok;

    $ok = eval { $mod->new(); 1; };
    is $ok, undef, "new() with no param dies";

    $ok = eval { $mod->new(0); 1; };
    is $ok, undef, "new() with only one param dies";

    for (-1, 64){
        $ok = eval { $mod->new($_, 1); 1; };
        is $ok, undef, "new() with out-of-range cs param ($_) dies";
    }

    for (-1, 2){
        $ok = eval { $mod->new(0, $_); 1; };
        is $ok, undef, "new() with out-of-range channel  param ($_) dies";
    }
}

{ # good

    my $obj;

    my $ok = eval { $obj = $mod->new(5, 1); 1; };
    is $ok, 1, "new() returns ok with ok params";
    is ref $obj, $mod, "...and new() returns proper obj ok";
    is $wpi_setup->called, 1, "new() calls wiringPiSetupGpio() ok";

    is $obj->_cs, 5, "new() sets CS ok";
    is $obj->_channel, 1, "new() sets CS ok";
}

done_testing();
