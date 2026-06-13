use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

# In-process interrupt callback counter (a file lexical, not an env var gate)

my $interrupts = 0;

sub handler {
    $interrupts++;
}

my $pi = $mod->new(
    label => 't/203-dispatch_interrupts.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # dispatch_interrupts() is non-blocking: it drains whatever the ISR thread
    # has already queued and fires the callbacks, with no wait_interrupts() in
    # the loop. Pre-fill a known number of rising edges, then poll-drain
    # (bounded) until the ISR thread has delivered every record.

    my $edges = 3;

    $pin->set_interrupt(EDGE_RISING, \&handler);

    $pin->pull(PUD_DOWN);

    # trigger the interrupts (no wait_interrupts between them)

    for (1 .. $edges){
        $pin->pull(PUD_UP);
        select(undef, undef, undef, 0.02);
        $pin->pull(PUD_DOWN);
        select(undef, undef, undef, 0.02);
    }

    # Poll-drain: accumulate non-blocking drains until every edge has been
    # dispatched, or ~2s elapses (replaces a fixed 0.1s settle window)

    my $dispatched = 0;

    for (1 .. 40){
        $dispatched += $pi->dispatch_interrupts();
        last if $dispatched >= $edges;
        select(undef, undef, undef, 0.05);
    }

    is $dispatched, $edges, "dispatch_interrupts() dispatched $edges total ok";
    is $interrupts, $edges,
        "callback fired $edges times without wait_interrupts ok";

    # nothing left pending - a second drain reports zero

    my $empty = $pi->dispatch_interrupts();

    is $empty, 0, "dispatch_interrupts() returns 0 when nothing pending ok";
    is $interrupts, $edges, "callback not re-fired on empty drain ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
