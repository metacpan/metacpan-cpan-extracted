use strict;
use warnings;

use lib 't/';

use RPiTest qw(check_pin_status);
use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);
use Test::More;

my $mod = 'RPi::WiringPi';

if (! $ENV{PI_BOARD}){
    warn "\n*** PI_BOARD is not set! ***\n";
    $ENV{NO_BOARD} = 1;
    plan skip_all => "not on a pi board\n";
    exit;
}

BEGIN {
    my $c;

    sub handler {
        $c++;
        $ENV{PI_INTERRUPT} = $c;
    }
}

my $pi = $mod->new;

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # EDGE_BOTH
    
    $pin->pull(PUD_DOWN);

    $pin->set_interrupt(EDGE_BOTH, 'main::handler');

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    is $ENV{PI_INTERRUPT}, 2, "both interrupt up/down == 2 ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);
    
    is $ENV{PI_INTERRUPT}, 4, "both interrupt up/down x2 == 4 ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);
    
    is $ENV{PI_INTERRUPT}, 6, "both interrupt up/down x3 == 6 ok";
    
}

$pi->cleanup;

check_pin_status();

done_testing();
