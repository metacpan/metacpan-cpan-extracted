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
    label => 't/208-auto_dispatch_interrupts.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # auto_dispatch_interrupts(1, $sig) wires the interrupt pipe for async
    # signal delivery: edges raise the signal and Perl's safe handler runs
    # dispatch_interrupts() between ops. We prove it by advancing the counter
    # in a SLEEP-ONLY poll loop - never calling wait/dispatch ourselves.

    my $edges = 3;

    $pin->set_interrupt(EDGE_RISING, \&handler);
    $pin->pull(PUD_DOWN);

    # SIGIO delivery (the default signal)

    my $base = $interrupts;

    $pi->auto_dispatch_interrupts(1, 'IO');

    for (1 .. $edges){
        $pin->pull(PUD_UP);
        select(undef, undef, undef, 0.05);
        $pin->pull(PUD_DOWN);
        select(undef, undef, undef, 0.05);
    }

    poll_until(sub { $interrupts >= $base + $edges });

    is $interrupts, $base + $edges,
        "SIGIO auto-dispatch delivered $edges edges (sleep-only loop) ok";

    $pi->auto_dispatch_interrupts(0);

    # SIGUSR1 delivery (a non-default signal wired via F_SETSIG)

    my $base2 = $interrupts;

    $pi->auto_dispatch_interrupts(1, 'USR1');

    for (1 .. $edges){
        $pin->pull(PUD_UP);
        select(undef, undef, undef, 0.05);
        $pin->pull(PUD_DOWN);
        select(undef, undef, undef, 0.05);
    }

    poll_until(sub { $interrupts >= $base2 + $edges });

    is $interrupts, $base2 + $edges,
        "SIGUSR1 auto-dispatch delivered $edges edges (sleep-only loop) ok";

    $pi->auto_dispatch_interrupts(0);
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();

# sleep-only wait: spins select() (never wait/dispatch_interrupts) until the
# async signal handler has advanced the counter, or a ~2s ceiling elapses.
sub poll_until {
    my ($cond) = @_;

    for (1 .. 40){
        last if $cond->();
        select(undef, undef, undef, 0.05);
    }
}
