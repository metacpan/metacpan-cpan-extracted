use strict;
use warnings;

use lib '.';

use RPi::WiringPi;
use RPi::WiringPi::Constant qw(:all);
use RPi::WiringPi::Interrupt;
use Test::More;

my $mod = 'RPi::WiringPi';

my $run;

BEGIN {
    if ($> == 0){
        $ENV{PI_BOARD} = 1;
        $run = 1;
    }

    if (! $ENV{PI_BOARD}){
        warn "\n*** PI_BOARD is not set! ***\n";
        $ENV{NO_BOARD} = 1;
        plan skip_all => "not on a pi board\n";
    }

    if ($> != 0){
        print "enforcing sudo for Interrupt tests...\n";
        system('sudo', 'perl', $0);
        exit;
    }
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

if (! $ENV{NO_BOARD}){

    my $pin = $pi->pin(18);

    $pin->interrupt_set(EDGE_RISING, 'main::handler');

    $pin->pull(PUD_DOWN);

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);

    is $ENV{PI_INTERRUPT}, 1, "1st interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);
    
    is $ENV{PI_INTERRUPT}, 2, "2nd interrupt ok";

    # trigger the interrupt

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);
    
    is $ENV{PI_INTERRUPT}, 3, "3rd interrupt ok";
    
}

$pi->cleanup;

# interrupt via main module

if (! $ENV{NO_BOARD}){

    my $int = RPi::WiringPi->interrupt(18, EDGE_RISING, 'handler');

    my $pin = $pi->pin(18);
    $pin->pull(PUD_DOWN);

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);
    
    is $ENV{PI_INTERRUPT}, 4, "4th interrupt ok, using interrupt object";

    $pin->pull(PUD_UP);
    $pin->pull(PUD_DOWN);
    
    is $ENV{PI_INTERRUPT}, 5, "5th interrupt ok, using interrupt object";

}

$pi->cleanup;

done_testing();
