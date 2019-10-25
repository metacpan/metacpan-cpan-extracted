use strict;
use warnings;

use lib '.';

use RPi::Pin;
use Test::More;

my $mod = 'RPi::Pin';

my $run;

BEGIN {
    if (! $ENV{RPI_SUBMODULE_TESTING}){
        plan(skip_all => "RPI_SUBMODULE_TESTING environment variable not set");
    }

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

# pin specific interrupts

if (! $ENV{NO_BOARD}){

    my $pin = $mod->new(18);

    # EDGE_RISING
    $pin->set_interrupt(2, 'main::handler');

    $pin->pull(1); # PUD_DOWN

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN

    is $ENV{PI_INTERRUPT}, 1, "1st interrupt ok";

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    is $ENV{PI_INTERRUPT}, 2, "2nd interrupt ok";

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    is $ENV{PI_INTERRUPT}, 3, "3rd interrupt ok";

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    is $ENV{PI_INTERRUPT}, 4, "4th interrupt ok";
 
    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    is $ENV{PI_INTERRUPT}, 5, "5th interrupt ok";

}

done_testing();
