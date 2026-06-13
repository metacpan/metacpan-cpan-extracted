# Interrupts in RPi::WiringPi

A practical guide to handling GPIO interrupts (edge events) with
`RPi::WiringPi`. Interrupts are **armed on a pin** and **driven from the Pi
object**:

- **Arm** on a pin object: `$pin->set_interrupt(...)` or
  `$pin->background_interrupt(...)` (see [RPi::Pin](https://metacpan.org/pod/RPi::Pin)).
- **Drive and control** dispatch on the Pi object `$pi`: `wait_interrupts`,
  `run_interrupt_loop`, `dispatch_interrupts`, `auto_dispatch_interrupts`,
  `stop_interrupts`, `last_interrupt`, `interrupt_buffer`,
  `background_interrupts`.

The split is deliberate: arming concerns a single pin, but the dispatch queue
and signal wiring are **process-wide** (one shared event pipe), so those live on
`$pi`, not on individual pins.

> **The #1 gotcha:** as of `WiringPi::API` 3.18 a callback does **not** auto-fire.
> It runs in *your* interpreter only when you service dispatch. So after arming
> you must drive dispatch (a loop, or `auto_dispatch_interrupts`, or a background
> process). The callback **must be a code reference** — string sub names are no
> longer accepted.

## Quick start

```perl
use RPi::WiringPi;
use RPi::Const qw(:all);

my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(18);
$pin->mode(INPUT);

# arm: callback gets ($edge, $timestamp_us)
$pin->set_interrupt(EDGE_RISING, sub {
    my ($edge, $ts_us) = @_;
    print "rising edge at $ts_us us\n";
});

# drive dispatch (callbacks fire here, in this process)
$pi->wait_interrupts(1000) while 1;
```

## Driving dispatch

Pick whichever fits your program. All of these live on `$pi`:

```perl
# 1) block until an edge (or timeout ms), then dispatch:
$pi->wait_interrupts(1000) while 1;

# 2) the built-in loop helper (so you don't write the 'while 1' yourself):
$pi->run_interrupt_loop(1000);          # forever
$pi->run_interrupt_loop(1000, 50);      # ... or until 50 events
#    break out from a callback or signal handler with:
$pi->stop_interrupt_loop;

# 3) non-blocking, from inside your own event loop:
$pi->dispatch_interrupts;               # run any pending callbacks, return count
```

## Hands-off: fire callbacks with no loop

`auto_dispatch_interrupts` wires the event pipe to a signal so callbacks fire
automatically, in your own process, at safe points — no dispatch loop, and the
callback can touch your program's variables with no locking. It is a
**process-wide** switch (it affects every armed pin), which is why it lives on
`$pi`.

```perl
$pi->auto_dispatch_interrupts(1);       # on (default SIGIO)
$pin->set_interrupt(EDGE_RISING, sub { $count++ });
# ... your program runs; the callback fires on its own ...
$pi->auto_dispatch_interrupts(0);       # off

# choose a different delivery signal to avoid clashing with other SIGIO users:
$pi->auto_dispatch_interrupts(1, 'USR1');
```

You can also opt in while arming, instead of a separate call:

```perl
$pin->set_interrupt(EDGE_RISING, \&handler, { auto_dispatch => 1 });
# or:  { auto_dispatch => 'USR1' }
```

Caveat: a long, non-yielding C/XS call defers the callback until it returns. If
you need it to fire even then, use a background process (below).

## Background handling (one process, fires even while main is busy)

> **Dependency note:** the per-pin `$pin->background_interrupt` form shown in this
> section is not available yet — `RPi::Pin` (as of `2.3608`) implements only
> `set_interrupt`. A future `RPi::Pin` release must ship the method first. Until
> then, use the multi-pin `$pi->background_interrupts` form
> ([below](#many-pins-in-one-background-child)), which works today.

`$pin->background_interrupt` forks a child that runs the handler on each edge
while your main program does anything it likes. The handler runs in the child,
so it **can't** touch your main variables — use it for independent work (drive a
pin, log, notify).

```perl
my $h = $pin->background_interrupt(EDGE_RISING, sub {
    my ($edge, $ts_us) = @_;
    # independent work, in the background
});
# ... main carries on ...
$h->stop;        # stop + reap (idempotent); $h->pid / $h->running too
```

To get values back from the handler, enable the **results channel** and *return*
a value:

```perl
my $h = $pin->background_interrupt(EDGE_RISING, sub {
    my ($edge, $ts_us) = @_;
    return "$edge\@$ts_us";
}, { results => 1 });

while (defined(my $msg = $h->read)) {   # non-blocking drain in the parent
    print "handler said: $msg\n";
}
# $h->fh is the read filehandle, for select / IO::Select
```

## Many pins in one background child

`$pi->background_interrupts` is the multi-pin version: **one** child services
several pins (instead of one child per pin), with runtime arm/disarm. Because it
spans several pins it lives on `$pi`.

```perl
my $h = $pi->background_interrupts(
    [18, EDGE_RISING, \&on_button],
    [23, EDGE_BOTH,   \&on_sensor, 5000],   # optional debounce (us)
);

$h->disarm(23);   # stop servicing pin 23 (child keeps running for pin 18)
$h->arm(23);      # resume it
$h->stop;         # tear down + reap the single child
```

The callbacks are fixed when the child forks, so `arm`/`disarm` only toggle pins
that were in the initial list (arming an unregistered pin croaks).

## Inspecting the most recent event

The callback only receives `($edge, $timestamp_us)`. If one shared handler is
armed on several pins, `$pi->last_interrupt` tells you which fired:

```perl
my $cb = sub {
    my $i = $pi->last_interrupt;   # { pin, pin_bcm, edge, status, ts_us }
    printf "pin %d (BCM %d) edge %d\n", $i->{pin}, $i->{pin_bcm}, $i->{edge};
};
$pi->pin($_)->set_interrupt(EDGE_BOTH, $cb) for (18, 23);
```

It returns the most recently dispatched event (or `undef`), and is published
*before* the callback runs, so the callback can read it.

## Queue sizing and dropped edges

Edges are FIFO-queued in a kernel pipe. If a fast source outruns your
dispatching the queue fills and the **newest** edges are dropped (never merged,
never blocked) and counted — so loss is never silent:

```perl
my $lost = $pi->interrupt_dropped;               # 0 unless the pipe overflowed
$pi->interrupt_buffer(1 << 20);                  # enlarge the queue (~1 MiB)
my $size = $pi->interrupt_buffer;                # read the current capacity
```

`interrupt_buffer` may be set before arming and persists across teardown. Other
mitigations: dispatch faster, use a background process, or debounce.

## Forking and cleanup

`$pi->cleanup` (called automatically at object destruction) resets pins **and**
releases armed interrupts (it calls `stop_interrupts` for you). It is
**fork-aware**: in a forked child the call is a no-op, so a child can't reset the
parent's pins or tear down its interrupts on exit. You can also disarm
explicitly while running:

```perl
$pin->set_interrupt(EDGE_RISING, \&handler);
# ... later ...
$pi->stop_interrupts;     # release every armed interrupt
$pi->cleanup;             # full teardown (also releases interrupts)
```

## Method reference

Arming methods live on a **pin** object (`my $pin = $pi->pin($n)`):

| Method (on `$pin`) | What it does |
|---|---|
| `set_interrupt($edge, $cb [, $debounce_us] [, \%opts])` | arm an interrupt; `\%opts` may include `{auto_dispatch => 1\|$signal}` |
| `background_interrupt($edge, $cb [, $debounce_us] [, \%opts])` | handle it in a forked child; `\%opts` may include `{results => 1}`; returns a handle |

Dispatch and control methods live on the **Pi** object (`$pi`):

| Method (on `$pi`) | What it does |
|---|---|
| `wait_interrupts($timeout_ms)` | block until an edge/timeout, then dispatch |
| `run_interrupt_loop($timeout_ms [, $max])` / `stop_interrupt_loop` | built-in blocking dispatch loop |
| `dispatch_interrupts` | non-blocking: run pending callbacks |
| `auto_dispatch_interrupts($bool [, $signal])` | fire callbacks automatically (no loop) |
| `background_interrupts([$pin,$edge,$cb[,$deb]], ...)` | one shared child for many pins (+ `arm`/`disarm`) |
| `last_interrupt` | hashref of the most recent dispatched event |
| `interrupt_buffer([$bytes])` | get/set the event-queue capacity |
| `interrupt_dropped` | running count of edges dropped on queue overflow |
| `stop_interrupts` | release every armed interrupt |

Edge constants (`EDGE_FALLING`=1, `EDGE_RISING`=2, `EDGE_BOTH`=3) and `INPUT`
come from `RPi::Const qw(:all)`.

See also `perldoc RPi::WiringPi::INTERRUPTS` (this guide in perldoc form),
[threads-examples.md](threads-examples.md) for running background work with
`$pi->worker`, the
[RPi::WiringPi::FAQ](https://metacpan.org/pod/RPi::WiringPi::FAQ) "Interrupt usage"
section, and the underlying [WiringPi::API](https://metacpan.org/pod/WiringPi::API)
documentation.
