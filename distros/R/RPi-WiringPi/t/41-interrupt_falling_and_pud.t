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

    # EDGE_FALLING

    $pin->set_interrupt(EDGE_FALLING, 'main::handler');

    $pin->pull(PUD_UP);

    # trigger the interrupt

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);

    is $ENV{PI_INTERRUPT}, 1, "1st interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);
    
    is $ENV{PI_INTERRUPT}, 2, "2nd interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_DOWN);
    $pin->pull(PUD_UP);
    
    is $ENV{PI_INTERRUPT}, 3, "3rd interrupt ok";
    
    $pin->pull(PUD_DOWN);
}

$pi->cleanup;

check_pin_status();

done_testing();
