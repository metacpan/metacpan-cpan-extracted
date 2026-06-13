# Concurrency & background workers in RPi::WiringPi

Worked, runnable examples for running background work concurrently with your main
program using the object-oriented `RPi::WiringPi`. The `$pi->worker` method is a
thin proxy onto `WiringPi::API::worker()` (shipped in `WiringPi::API` 3.18 and
verified on Pi 5 hardware); the snippets run as written.

`$pi->worker` is **fork-based by default and needs no `use threads` and no
threaded Perl** — an ithread mechanism is a documented opt-in only. For reacting
to GPIO *edges* in the background, see [interrupt-examples.md](interrupt-examples.md).

This is the markdown form of `perldoc RPi::WiringPi::WORKERS`. See `perldoc
RPi::WiringPi` for the `worker()` per-method reference.

## About these examples

- **Prefer `$pi->worker`.** It hides the spawn mechanism, the loop **and** the
  lifecycle: your body carries no `fork`, no `use threads`, no `detach`, no
  `while (1)` and no cleanup. It is the general-purpose sibling of
  `$pi->background_interrupts`.
- **The object owns the lifecycle.** Every handle returned by `$pi->worker` is
  tracked on the object; `$pi->cleanup` (and therefore `DESTROY`) stops them all.
  You *can* `$w->stop` a worker yourself, but you never have to.
- **No threads required.** `$pi->worker` forks by default and works on **any**
  Perl, threaded or not. The ithread mechanism (scenario 6) is an opt-in for
  users who specifically want shared-memory ergonomics on a threaded Perl.
- **Pin numbering** follows the object's scheme (BCM/GPIO by default). Configure
  pins through the object — `my $pin = $pi->pin($n); $pin->mode(OUTPUT)` — once,
  in the parent, before starting a worker.
- Scenarios 7–8 ("under the hood") show the raw `fork` / `threads->create`
  plumbing that `$pi->worker` packages up — read them to understand what happens
  beneath the method, but most programs only need `$pi->worker`.

## Decision guide

None of these need `use threads` except scenario 6. To hide the most plumbing,
use `$pi->worker` (scenarios 1–5).

**fork vs thread in one line:** the default `fork` worker is crash-isolated and
works on any Perl but **can't touch main's variables** (hand data back with
`results`/`shared`); a `mechanism => 'thread'` worker shares memory directly but
needs a threaded Perl and `pi_lock` discipline. No shared-memory need? Use the
default fork.

- Run a background task and forget it (its own GPIO) — scenario 1.
- Sample periodically; main reads the latest value — scenario 2 (`interval`/`shared`).
- Stream every value the worker produces back to main — scenario 3 (`results`).
- Do one background job once, then exit — scenario 4 (`once`).
- Several independent workers, each on its own pin — scenario 5.
- Share memory directly between main and the worker — scenario 6 (`mechanism => 'thread'`).
- React to a pin edge in the background — `$pi->background_interrupts` (see
  [interrupt-examples.md](interrupt-examples.md)).
- Understand/hand-roll the raw mechanism — scenarios 7, 8.

## Background workers (`$pi->worker`)

### 1. Heartbeat LED — a worker on its own pin

A self-contained background task on its own GPIO while main does its own work.
The method owns the loop and the lifecycle; you write only the body.

```perl
use strict;
use warnings;
use RPi::WiringPi;
use RPi::Const qw(:all);

my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(2);
$pin->mode(OUTPUT);               # once, in main

my $w = $pi->worker(sub {
    $pin->write(HIGH); sleep 1;
    $pin->write(LOW);  sleep 1;
});

# ... main does its own work ...

$pi->cleanup;                     # stops $w (and every other worker) for you
```

No `use threads`, no `fork`, no `detach`, no `while (1)`, no `waitpid`. You could
also `$w->stop` the heartbeat by hand (idempotent); `cleanup` just makes it
automatic.

### 2. Periodic sampler handing data back (`interval` + `shared`)

`{ interval => $secs }` paces the loop (the body needs no `sleep`);
`{ shared => 1 }` publishes the body's return value as a lossy latest value the
parent reads with `$w->value`.

```perl
my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(4);
$pin->mode(INPUT);                # once, in main

my $w = $pi->worker(sub { $pin->read }, { interval => 1, shared => 1 });

for (1 .. 5) {
    my $latest = $w->value;       # most recent sample, or undef until the first
    print "latest: ", (defined $latest ? $latest : 'n/a'), "\n";
    sleep 5;
}

$pi->cleanup;
```

The channel is **lossy** — the worker never blocks on a slow reader, so `value()`
gives you the most recent sample and discards the ones you didn't read.

### 3. Streaming every result (`results`)

`{ results => 1 }` length-frames every defined return value back over a pipe.
Drain it with `$w->read` (non-blocking), or select on `$w->fh`.

```perl
my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(4);
$pin->mode(INPUT);                # once, in main

my $w = $pi->worker(sub { $pin->read }, { interval => 0.5, results => 1 });

for (1 .. 20) {
    while (defined(my $v = $w->read)) {   # drain everything pending
        print "sample: $v\n";
    }
    sleep 1;
}

$pi->cleanup;
```

This is identical to `$pi->background_interrupts`' `{ results => 1 }` channel.

### 4. A one-shot background task (`once`)

`{ once => 1 }` runs the body exactly once; the child then exits and
`$w->running` becomes false.

```perl
my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(5);
$pin->mode(OUTPUT);               # once, in main

my $w = $pi->worker(sub {
    $pin->write(HIGH);
    select(undef, undef, undef, 0.2);     # 200ms pulse
    $pin->write(LOW);
}, { once => 1 });

# ... main carries on; the pulse fires in the background ...

$pi->cleanup;                     # the pulse has usually already finished
```

### 5. Several workers on distinct pins

Configure every pin **once in main**, then start one worker per pin. Each runs
independently and returns its own handle; all are tracked on the object and
stopped together by `$pi->cleanup`.

```perl
my $pi = RPi::WiringPi->new;

my @pins = map { my $p = $pi->pin($_); $p->mode(OUTPUT); $p } (23, 24, 25);

my @workers = map {
    my $pin = $_;
    $pi->worker(sub { $pin->write(HIGH); sleep 1; $pin->write(LOW); sleep 1 });
} @pins;

# ... main's own work ...

$pi->cleanup;                     # stops all @workers at once
```

Workers must drive **distinct** pins — see [The setup-once-in-main
contract](#the-setup-once-in-main-contract).

### 6. Shared memory — the opt-in ithread mechanism

`{ mechanism => 'thread' }` runs the body in an ithread instead of a fork. It
**requires** `use threads` (croaks otherwise) and rejects the `results`/`shared`
pipe channels — share a `:shared` variable and serialize it with
`WiringPi::API::pi_lock`/`WiringPi::API::pi_unlock` (keys 0–3) instead. There is
**no** OO proxy for the lock — thread mode is a niche opt-in, so you call the
`WiringPi::API` functions directly.

```perl
use strict;
use warnings;
use threads;                      # required for mechanism => 'thread'
use threads::shared;
use RPi::WiringPi;
use WiringPi::API qw(pi_lock pi_unlock);

my $pi = RPi::WiringPi->new;

my $count :shared = 0;

my $w = $pi->worker(sub {
    pi_lock(0);
    $count++;
    pi_unlock(0);
    select(undef, undef, undef, 0.1);
}, { mechanism => 'thread' });

for (1 .. 5) {
    pi_lock(0);
    my $n = $count;
    pi_unlock(0);
    print "count: $n\n";
    sleep 1;
}

$w->stop;                         # sets the stop flag and joins
```

Check for a threaded Perl with `perl -V:useithreads` (Raspberry Pi OS ships one).
The fork default (scenarios 1–5) never locks and never needs `threads`.

## Reacting to interrupts in the background

`$pi->worker` is for *running* background work, not for reacting to GPIO **edges**.
To handle an edge in the background — fire a callback even while main is blocked —
use **`$pi->background_interrupts`**, the interrupt-side sibling of `worker`. It
forks a single child that arms one or more pins and runs your callback on each
edge, returning a handle with the same `stop`/`pid`/`running` shape (plus
`arm`/`disarm`):

```perl
my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(4);
$pin->mode(INPUT);

my $h = $pi->background_interrupts(
    [4, EDGE_RISING, \&on_edge, 0],
);

# ... main does its own work; the handler fires on its own ...

$pi->cleanup;                     # stops interrupts and workers together

sub on_edge { ... }               # runs in the background child on each edge
```

The full interrupt story is in [interrupt-examples.md](interrupt-examples.md) /
`perldoc RPi::WiringPi::INTERRUPTS`.

## The setup-once-in-main contract

The rule that keeps concurrent GPIO safe: do all configuration **once, in main,
before** starting any worker; afterwards each context does only steady-state I/O
on **distinct** pins.

- Construct the object and configure every pin (`$pi->pin($n)`, `$pin->mode(...)`)
  and any device **once, in the parent, before** the first `$pi->worker`.
- A fork worker inherits that configuration; a thread worker shares it.
- Afterwards, workers may freely read/write on **distinct** pins. **Never**
  configure pins or set up devices concurrently — they read-modify-write shared
  registers.
- For shared Perl data under `mechanism => 'thread'`, guard every access with
  `WiringPi::API::pi_lock`/`WiringPi::API::pi_unlock` (or `threads::shared`'s
  `lock`).
- A forked worker shares the `$pi` object but must not tear it down: the
  process-guard in `cleanup()` ensures only the parent stops workers and restores
  pins, so a worker exiting never disturbs the parent's state.

## Under the hood

These are the raw mechanisms `$pi->worker` packages up. You rarely need them
directly.

### 7. Manual fork

```perl
my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(2);
$pin->mode(OUTPUT);                      # before fork

my $kid = fork // die "fork: $!";

if ($kid == 0) {
    while (1) {                          # child: heartbeat forever
        $pin->write(HIGH); sleep 1;
        $pin->write(LOW);  sleep 1;
    }
    exit 0;
}

# ... parent's own work ...

kill 'TERM', $kid;                       # on shutdown
waitpid $kid, 0;
```

`$pi->worker(sub {...})` is exactly this — the fork, the loop, the `TERM` handler
and the `waitpid` — done for you, with an idempotent `stop`, automatic reaping in
`$pi->cleanup`, and an END-block safety net in `WiringPi::API`.

### 8. Raw ithreads (`threads->create`)

```perl
use threads;
use threads::shared;
use RPi::WiringPi;
use WiringPi::API qw(pi_lock pi_unlock);

my $pi  = RPi::WiringPi->new;
my $pin = $pi->pin(4);
$pin->mode(INPUT);

my $latest :shared = 0;

my $thr = threads->create(sub {
    while (1) {
        my $v = $pin->read;
        pi_lock(0); $latest = $v; pi_unlock(0);
        select(undef, undef, undef, 0.05);
    }
});

# ... main reads $latest under pi_lock(0) ...

# To stop a hand-rolled thread you need your own shared flag + join;
# $pi->worker({mechanism=>'thread'}) provides exactly that.
$thr->detach;
```

`$pi->worker(sub {...}, { mechanism => 'thread' })` wraps this with a shared stop
flag and a clean `stop`/join, so you don't hand-roll the lifecycle.

## Anti-patterns to avoid

- **Reaching for `use threads` first.** `$pi->worker` is fork-based and needs no
  threaded Perl. Only use `mechanism => 'thread'` when you specifically want
  shared memory.
- **Putting a loop inside the body.** `$pi->worker` owns the loop — the body is
  one pass. Use `{ interval => $secs }` for pacing and `{ once => 1 }` for a
  single pass; a `while (1)` inside the body defeats `stop`/`once`/`interval`.
- **Concurrent pin configuration / device setup.** Read-modify-write on shared
  registers; do them once, in main, before starting any worker. Only reads/writes
  on distinct pins are safe concurrently.
- **Expecting a fork worker to see main's variables.** Separate memory — hand
  data back with `{ results => 1 }` / `{ shared => 1 }`, not a shared Perl
  variable.
- **Touching `:shared` data without a lock (thread mode).** Guard every access
  with `pi_lock`/`pi_unlock` (or `lock`). A bare `$shared++` from two threads
  races.
- **Combining `mechanism => 'thread'` with `results`/`shared`.** Those are fork
  pipe channels and are rejected under thread mode — share a `:shared` variable
  with `pi_lock` instead.

## See also

- `perldoc RPi::WiringPi::WORKERS` — this guide in perldoc form
- `perldoc RPi::WiringPi` — the `worker()` per-method reference
- [interrupt-examples.md](interrupt-examples.md) — reacting to GPIO edges
- `perldoc WiringPi::API` and `perldoc WiringPi::API::WORKERS` — the low-level
  functional API
