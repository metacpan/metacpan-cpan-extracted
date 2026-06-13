use strict;
use warnings;

use lib 't/';

use RPiTest;
use RPi::WiringPi;
use RPi::Pin;
use RPi::Const qw(:all);
use Test::More;

rpi_running_test(__FILE__);

# Pin-level background_interrupt() is provided by RPi::Pin >= 2.3609 (earlier
# releases only inherit a non-functional method via @ISA to WiringPi::API).
# Skip cleanly on older installs so this activates automatically once the
# dependency is in place.

if ($RPi::Pin::VERSION < 2.3609){
    plan skip_all =>
        "RPi::Pin $RPi::Pin::VERSION has no real pin-level background_interrupt "
        . "(need >= 2.3609)";
}

my $mod = 'RPi::WiringPi';

my $pi = $mod->new(
    label => 't/212-pin_background_interrupt.t',
    shm_key => 'rpit',
    shared => 0
);

my $pin = $pi->pin(18);

if (! $ENV{NO_BOARD}){

    # background_interrupt() forks a child that owns the pin's ISR. With
    # {results => 1} the callback's return value is shipped back over a pipe;
    # the parent drives edges and drains them via the handle's ->read / ->fh.

    my $edges = 3;

    my $h = $pin->background_interrupt(EDGE_RISING, \&bg_cb, 0, {results => 1});

    ok $h->running, "pin background interrupt child is running ok";
    cmp_ok $h->pid, '>', 0, "background child pid is positive ok";
    ok defined $h->fh, "results channel (->fh) is wired ok";

    $pin->pull(PUD_DOWN);

    for (1 .. $edges){
        $pin->pull(PUD_UP);
        select(undef, undef, undef, 0.05);
        $pin->pull(PUD_DOWN);
        select(undef, undef, undef, 0.05);
    }

    # drain the results channel; ->read is non-blocking, so poll until we have
    # one value per driven edge (or a ~2s ceiling elapses)

    my @got;

    for (1 .. 40){
        last if @got >= $edges;
        my $r = $h->read;
        if (defined $r){
            push @got, $r;
            next;
        }
        select(undef, undef, undef, 0.05);
    }

    is scalar(@got), $edges, "drained $edges results via ->read ok";
    is_deeply [grep { $_ == EDGE_RISING } @got], [(EDGE_RISING) x $edges],
        "each result reports the rising edge ok";

    $h->stop;

    ok ! $h->running, "after stop() the child is reaped (running false) ok";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();

# child-side callback: its return value is framed back to the parent
sub bg_cb {
    my ($edge, $ts_us) = @_;
    return $edge;
}
