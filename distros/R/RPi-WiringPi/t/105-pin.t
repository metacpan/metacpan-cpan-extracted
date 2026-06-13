use strict;
use warnings;

use lib 't/';

use Data::Dumper;
use RPi::WiringPi;
use RPiTest;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

my $pi = $mod->new(label => 't/105-pin.t', shm_key => 'rpit');

{# pin

    my $pin = $pi->pin(18, "test");

    isa_ok $pin, 'RPi::Pin';
    is $pin->comment, 'test', "comment sent in new ok";
    is $pin->comment('t/105-pin.t'), 't/105-pin.t', "comment() sets and gets the comment ok";

    is $pin->mode, 0, "pin mode is INPUT by default";
    is $pin->read, 0, "pin status is LOW by default";

    $pin->mode(1);

    is $pin->mode, 1, "pin mode is OUTPUT ok";
    
    is $pin->read, 0, "pin status is LOW after going OUTPUT mode";

    $pin->write(1);

    is $pin->read, 1, "pin status HIGH after write(1)";

    $pin->write(0);

    is $pin->read, 0, "pin status back to LOW after write(0)";

    $pin->mode(0);

    is $pin->mode, 0, "pin mode back to INPUT";
}

$pi->cleanup;

#rpi_check_pin_status();

done_testing();
