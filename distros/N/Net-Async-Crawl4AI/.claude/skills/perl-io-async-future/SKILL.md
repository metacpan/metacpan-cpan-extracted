---
name: Perl IO::Async + Future
description: Async Perl with IO::Async, Future, Future::AsyncAwait — lifecycle, retention, cancellation, reconnect patterns from PEVANS modules and battle-tested fixes
trigger: when working with IO::Async, Future, Future::AsyncAwait, Net::Async::*, async/await in Perl
category: language
---

# Perl IO::Async + Future — Patterns & Pitfalls

PEVANS-style async Perl. The framework is small but its lifetime rules are *unforgiving*: a Future that nobody holds gets garbage-collected mid-flight, and the symptom is rarely a clear error.

## The One Rule That Causes 80% of Bugs

**You MUST retain every Future you care about until it is ready.**

A Future is just a Perl object. When the last reference drops, it is destroyed — even if it represents an in-flight async operation. The op may continue, complete, or wedge, but nobody will hear about it. With `Future::AsyncAwait` you'll see:

> Suspended async sub Foo::bar lost its returning future

Without async/await, you'll see *nothing* — just a hang or a callback that never fires.

**Fix:** store the Future on `$self->{_some_future}` (or in any container that outlives the operation). Local-variable-only is a bug unless the local *waits* (`->get`, `await`) before returning.

---

## Pattern 1 — Notifier Subclass Skeleton

```perl
package Net::Async::Foo;
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future;
use Future::AsyncAwait;
use IO::Async::Stream;

sub configure {
    my ($self, %params) = @_;
    for my $key (qw(host port on_connect on_error)) {
        $self->{$key} = delete $params{$key} if exists $params{$key};
    }
    $self->{host} //= 'localhost';
    $self->SUPER::configure(%params);   # MUST chain — unknown keys die here
}

sub host { $_[0]->{host} }
```

**Rules:**
- `delete` your keys from `%params` before `SUPER::configure` — leftover keys throw `configure_unknown`.
- Parameter validation/defaults go in `configure`, **not** `new` (Notifier owns construction).
- A Notifier only knows its loop after `$loop->add($notifier)` — anything that calls `$self->loop` must run after that.
- Child notifiers (`IO::Async::Stream`, `IO::Async::Timer`) attach via `$self->add_child($child)`; they inherit the loop automatically.

---

## Pattern 2 — TCP Connect (the GC trap)

```perl
async sub connect {
    my ($self) = @_;

    my $stream = IO::Async::Stream->new(
        on_read       => sub { $self->_on_read(@_) },
        on_read_eof   => sub { $self->_on_disconnect('read_eof') },
        on_read_error => sub { $self->_on_error("read: $_[1]") },
    );
    $self->{_stream} = $stream;
    $self->add_child($stream);

    # ⚠️ RETAIN the connect Future. If GC'd, the stream never gets its
    # handle and on_read never fires — silent hang.
    $self->{_tcp_connect_future} = $stream->connect(
        host    => $self->{host},
        service => $self->{port},
    )->on_fail(sub {
        my $err = shift;
        $self->{_connect_future}->fail("connect: $err")
            unless $self->{_connect_future}->is_ready;
    });

    $self->{_connect_future} = $self->loop->new_future;
    return await $self->{_connect_future};
}
```

**Why both futures?** `_tcp_connect_future` resolves when the *socket* is up. `_connect_future` resolves when your *protocol handshake* is done. The handshake completes inside `on_read`, so you need a separate Future to await.

Clean up `_tcp_connect_future` once the handshake succeeds (`delete $self->{_tcp_connect_future}`).

---

## Pattern 3 — Reconnect Without Losing Futures

The reconnect path is where Future-lifetime bugs cluster. Wrong:

```perl
# ❌ BUG: $f is local to the closure, GC'd as soon as _reconnect returns
sub _reconnect {
    my $self = shift;
    my $f = $self->loop->delay_future(after => 2)->then(sub { $self->connect });
}
```

Right:

```perl
sub _reconnect_attempt {
    my ($self) = @_;
    return if $self->{_connected};

    weaken(my $weak = $self);

    $self->{_reconnect_future} = $self->loop
        ->delay_future(after => $self->{reconnect_wait})
        ->then(sub {
            my $self = $weak or return Future->done;
            return Future->done if $self->{_connected};
            return $self->connect;
        })
        ->on_done(sub {
            my $self = $weak or return;
            delete $self->{_reconnect_future};
        })
        ->on_fail(sub {
            my $self = $weak or return;
            delete $self->{_reconnect_future};
            $self->_reconnect_attempt;        # try again
        });
}
```

**Rules:**
- Store the *whole chain* on the object (`$self->{_reconnect_future}`), not just the leaf.
- `weaken` `$self` inside callbacks — otherwise the chain holds the object alive forever.
- Always `delete $self->{_reconnect_future}` in both `on_done` and `on_fail`, or you'll guard out future reconnects with `return if $self->{_reconnect_future}`.
- On disconnect, **cancel the old `_connect_future`** so its async sub unwinds:
  ```perl
  if (my $f = delete $self->{_connect_future}) {
      $f->fail("disconnected: $reason") unless $f->is_ready;
  }
  ```

---

## Pattern 4 — Future Composition

```perl
# Sequential dependency (then = "after this, do that")
$f1->then(sub { do_b(@_) })           # done → done branch
   ->else(sub { recover(@_) })        # fail → recovery branch
   ->then(sub { do_c(@_) });

# Parallel, all must succeed (fails fast, cancels siblings)
my $f = Future->needs_all($fa, $fb, $fc);
my @results = await $f;

# Race — first one wins, losers are cancelled
my $f = Future->wait_any($work, $self->loop->delay_future(after => 5)
                                   ->then_fail('timeout'));

# Observe without composing (does NOT chain — return value ignored)
$f->on_done(sub { warn "done: @_" });
$f->on_fail(sub { warn "failed: $_[0]" });
```

**`then` vs `on_done`:**
- `then` returns a *new* Future; the callback returns a Future to chain. Use for control flow.
- `on_done` returns the *same* Future; callback return value is discarded. Use for side-effects/observation.

**Protective composition** (Future ≥ 0.51): pass extra siblings via `also =>` to keep them alive without making cancellation propagate:
```perl
Future->needs_all($f1, also => $f2, $f3);
```

---

## Pattern 5 — `->retain` for Fire-and-Forget

When you legitimately want to start an op and not wait, but still need it to *finish*:

```perl
$self->_log_async($msg)
    ->on_fail(sub { warn "log failed: $_[0]" })
    ->retain;
```

`->retain` parks the Future on an internal global until it completes, then drops it. Without `retain`, the chain has no holder and gets GC'd before it runs. Use this only when you genuinely don't need the result — otherwise hold the Future yourself.

---

## Pattern 6 — Future::AsyncAwait (`async`/`await`)

```perl
use Future::AsyncAwait;

async sub fetch_user {
    my ($self, $id) = @_;
    my $row = await $self->db->query("SELECT ...", $id);
    my $perms = await $self->perms->for($id);
    return { %$row, perms => $perms };
}

# Caller MUST hold the returned Future:
my $f = $client->fetch_user(42);
my $user = await $f;        # ok
# OR:
my $user = await $client->fetch_user(42);   # also ok — await holds it
```

**Pitfalls:**
- **Returning a Future from `async sub` without `await`** double-wraps it. Final expression `return await $f`, not `return $f`.
- **`@_` is not preserved across `await` on Perl < 5.24.** Unpack args into lexicals at the top of the sub.
- **`await` inside `map`/`grep` does not work.** Convert to a `for` loop with an accumulator.
- **Caller drops the Future** → "Suspended async sub … lost its returning future". The async sub's continuation is destroyed mid-flight. Always store the Future or `await` it.
- The async sub itself does not retain its returning Future. **Storing the Future in the calling object is the cure**, not adding `->retain` inside the async sub.

---

## Pattern 7 — Timeouts

```perl
# delay_future returns a Future that resolves with no value after N seconds
my $timer = $self->loop->delay_future(after => 5);

# Race the work against the timer
my $result = await Future->wait_any(
    $work_future,
    $timer->then_fail('timeout'),
);
```

`then_fail($msg)` is shorthand for "when the upstream Future is done, fail with this message" — perfect for timeouts. There's also `->timeout($secs)` on Future ≥ 0.42.

---

## Pattern 8 — Cancellation Hygiene

```perl
# Before starting a new attempt, kill stale ones
if (my $f = delete $self->{_connect_future}) {
    $f->cancel unless $f->is_ready;
}
```

- `->cancel` is idempotent but only meaningful on a non-ready Future.
- `needs_all` cancels siblings on first failure; `wait_any` cancels losers on first success. You usually don't need to cancel manually inside a composition.
- A cancelled Future is *neither* done nor failed — `is_ready` is true but `result`/`failure` will throw. Check `is_cancelled` if you need to distinguish.

---

## Pattern 9 — Loops & Tests

```perl
use IO::Async::Loop;
my $loop = IO::Async::Loop->new;
$loop->add($client);

# Block-wait on a Future from sync code (test code, main script):
my @result = $client->connect->get;

# Run loop until a Future is ready (older style):
$loop->await($f);
```

**Test pattern:**
```perl
use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
testing_loop($loop);                # IO::Async::Test hook

my $client = MyClient->new(...);
$loop->add($client);

my $f = $client->do_thing;
wait_for_future($f);                # spins the loop
ok($f->is_done, 'completed');
is_deeply([$f->result], [...]);
```

---

## Decision Guide

| Situation | Use |
|---|---|
| Subclassing IO::Async object | `parent 'IO::Async::Notifier'`, override `configure` |
| Storing async state on $self | `$self->{_foo_future}` — never bare lexicals |
| Sequential dependent ops | `->then` / `async`+`await` |
| Parallel, all required | `Future->needs_all` |
| First-to-finish race | `Future->wait_any` |
| Add timeout to op | `wait_any($op, $loop->delay_future(after=>N)->then_fail('timeout'))` |
| Side-effect observation | `->on_done` / `->on_fail` (don't chain) |
| Truly fire-and-forget | `->retain` (rare — usually you should hold it) |
| Closure capturing $self | `weaken(my $weak = $self)` + null-check inside |
| Cancelling stale attempt | `delete $self->{_f}; $f->cancel unless $f->is_ready` |
| Sync block-wait (tests/scripts) | `$f->get` |

---

## Common Pitfalls (the recurring ones)

- **Local-variable-only Future** → silent GC. Hold it on `$self`.
- **Async sub whose caller drops the Future** → "lost its returning future". Hold the result.
- **Strong `$self` capture in callback chain** → object never destroyed; reconnect loops leak. `weaken` it.
- **Forgetting to `delete` the held Future on completion** → stale guards block future operations.
- **Not chaining `SUPER::configure`** → defaults silently missing, or unknown keys silently accepted.
- **Returning a Future from `async sub` without `await`** → double-wrapped result.
- **Calling `$self->loop` before `$loop->add($self)`** → `loop` is undef.
- **Mixing `then` and `on_done` thinking they're the same** → `on_done` returns the original Future, your "chain" is actually two parallel observers.
- **Cancelling a Future inside its own callback** → undefined; cancel from outside.
- **Using `Future->new` instead of `$loop->new_future`** when you need loop-aware behavior (the loop variant integrates with timeouts and is the recommended form inside Notifier subclasses).

---

## The Mental Model

A Future is a *handle to a result that may not exist yet*. It is also a *Perl SV with a refcount*. Both facts matter equally:

- As a handle, you compose, await, observe.
- As an SV, if nothing holds it, it disappears — and async work it represents either completes into the void or never completes at all.

Every async bug in this codebase has been one of: (a) nobody held the Future, (b) somebody held it too tightly via $self capture, or (c) the Future was held but never deleted, blocking the next operation. The patterns above exist to make all three impossible by construction.
