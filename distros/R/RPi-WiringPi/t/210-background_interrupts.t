use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

# background_interrupts() services edges in a forked child, so its callback
# cannot touch parent variables. The plural handle also exposes no results
# channel (->read/->fh are undef - see plan B4/D2), so the child reports each
# processed edge by appending a byte to a shared file the parent tallies. This
# lets us prove real edge-flow plus arm/disarm gating over the control pipe.

my $count_file = "/dev/shm/rpi-wiringpi-bg-interrupt.$$";

my $pi = $mod->new(
    label => 't/210-background_interrupts.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    unlink $count_file;

    my $h = $pi->background_interrupts([18, EDGE_RISING, \&bg_handler, 0]);

    ok $h->running, "background child is running ok";
    cmp_ok $h->pid, '>', 0, "background child pid is positive ok";

    $pin->pull(PUD_DOWN);

    # parent drives edges; the child processes them and grows the file

    drive_edges(3);
    wait_for_count(3);

    is processed(), 3, "child processed 3 driven edges ok";

    # disarm(18): the control pipe tells the child to stop the pin; further
    # edges must not be processed (tally frozen)

    is $h->disarm(18), 1, "disarm(18) accepted while running ok";

    # Deliberate fixed settles (not poll-able): the parent has no observable
    # "disarm applied" state, and the frozen-tally assertion below proves a
    # negative - a quiet window is the only way to let stray edges surface

    select(undef, undef, undef, 0.3);   # let the child apply the disarm

    drive_edges(3);
    select(undef, undef, undef, 0.3);

    is processed(), 3, "after disarm(18) edges are not processed (frozen) ok";

    # arm(18): re-arm over the control pipe; processing resumes

    is $h->arm(18), 1, "arm(18) accepted while running ok";

    # Re-arm application is asynchronous, so early edges may be lost - keep
    # driving single edges (bounded, ~20 attempts) until two get through,
    # instead of a fixed settle before driving

    for (1 .. 20){
        last if processed() >= 5;
        drive_edges(1);
        select(undef, undef, undef, 0.05);
    }

    is processed(), 5, "after arm(18) edge processing resumes ok";

    # unregistered pins croak on both control methods

    eval { $h->arm(99) };
    like $@, qr/pin must be one registered/, "arm(99) croaks (unregistered) ok";

    eval { $h->disarm(99) };
    like $@, qr/pin must be one registered/,
        "disarm(99) croaks (unregistered) ok";

    # stop reaps the child

    $h->stop;

    ok ! $h->running, "after stop() the child is reaped (running false) ok";

    unlink $count_file;
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();

# child-side callback: append one byte per processed edge to the shared file
sub bg_handler {
    open my $fh, '>>', $count_file or return;
    print $fh 'x';
    close $fh;
}

# parent-side: drive $n rising edges on the self-triggered pin
sub drive_edges {
    my ($n) = @_;

    for (1 .. $n){
        $pin->pull(PUD_UP);
        select(undef, undef, undef, 0.05);
        $pin->pull(PUD_DOWN);
        select(undef, undef, undef, 0.05);
    }
}

# parent-side: number of edges the child has processed so far
sub processed {
    return -s $count_file || 0;
}

# parent-side: poll (sleep) until the child's tally reaches $n or ~2s elapses
sub wait_for_count {
    my ($n) = @_;

    for (1 .. 40){
        last if processed() >= $n;
        select(undef, undef, undef, 0.05);
    }
}
