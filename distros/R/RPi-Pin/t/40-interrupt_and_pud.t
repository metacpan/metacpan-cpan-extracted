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
        $ENV{RPI_BOARD} = 1;
        $run = 1;
    }

    if (! $ENV{RPI_BOARD}){
        warn "\n*** RPI_BOARD is not set! ***\n";
        $ENV{NO_BOARD} = 1;
        plan skip_all => "not on a pi board\n";
    }

    if ($> != 0){
        print "enforcing sudo for Interrupt tests...\n";
        # Re-exec with $^X (the running perl) so sudo doesn't fall back to
        # the system perl, which lacks our perlbrew-installed prerequisites;
        # sudo scrubs the environment, so re-feed the gate var via env(1)
        system(
            "sudo", "env", "RPI_SUBMODULE_TESTING=$ENV{RPI_SUBMODULE_TESTING}",
            $^X, "-I", "blib/lib", "-I", "blib/arch", $0
        );
        exit;
    }
}

# In-process interrupt callback counter (a file lexical, not an env var gate)

my $interrupts = 0;

sub handler {
    $interrupts++;
}

# pin specific interrupts

if (! $ENV{NO_BOARD}){

    my $pin = $mod->new(18);

    # EDGE_RISING
    $pin->set_interrupt(2, \&main::handler);

    $pin->pull(1); # PUD_DOWN

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN

    $pin->wait_interrupts(500);
    is $interrupts, 1, "1st interrupt ok";

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    $pin->wait_interrupts(500);
    is $interrupts, 2, "2nd interrupt ok";

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    $pin->wait_interrupts(500);
    is $interrupts, 3, "3rd interrupt ok";

    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    $pin->wait_interrupts(500);
    is $interrupts, 4, "4th interrupt ok";
 
    # trigger the interrupt

    $pin->pull(2); # PUD_UP
    $pin->pull(1); # PUD_DOWN
    
    $pin->wait_interrupts(500);
    is $interrupts, 5, "5th interrupt ok";

}

done_testing();
