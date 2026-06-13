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
    label => 't/209-interrupt_buffer.t',
    shm_key => 'rpit',
    shared => 0
);

# pin specific interrupts

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # interrupt_buffer() sizes the self-pipe that backs the interrupt queue.
    # Arm first so a live pipe exists, capture the baseline, grow it, then run
    # a functional burst and confirm nothing was dropped. Restore at the end.

    $pin->set_interrupt(EDGE_RISING, \&handler);
    $pin->pull(PUD_DOWN);

    my $base = $pi->interrupt_buffer();

    cmp_ok $base, '>', 0, "baseline interrupt_buffer() is positive ok";

    # grow it; the kernel rounds up to a page, so assert >= requested

    my $req = $base * 2;
    my $granted = $pi->interrupt_buffer($req);

    cmp_ok $granted, '>=', $req,
        "interrupt_buffer(set) grants >= requested ($req) ok";
    cmp_ok $pi->interrupt_buffer(), '>=', $req,
        "interrupt_buffer(get) reflects the grown size ok";

    # functional burst: every edge counted, none dropped

    my $edges = 5;

    for (1 .. $edges){
        $pin->pull(PUD_UP);
        select(undef, undef, undef, 0.02);
        $pin->pull(PUD_DOWN);
        select(undef, undef, undef, 0.02);
    }

    select(undef, undef, undef, 0.1);

    is $pi->dispatch_interrupts(), $edges, "burst of $edges all dispatched ok";
    is $interrupts, $edges, "callback fired $edges times ok";
    is $pi->interrupt_dropped(), 0, "no interrupts dropped ok";

    # restore the baseline capacity

    $pi->interrupt_buffer($base);

    is $pi->interrupt_buffer(), $base,
        "interrupt_buffer() restored to baseline ($base) ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
