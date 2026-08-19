package Punk::Future;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.20';

1;

__END__

=head1 NAME

Punk::Future - an async result that runs on the loop, or blocks

=head1 SYNOPSIS

    my $f = Punk::Future->new;
    $f->on_done(sub { my @v = @_; ... });
    $f->done({ ok => 1 });

    # in a controller: resolve later, hand the future back
    get '/slow' => sub {
        my ($c) = @_;
        $c->timer(2)->then(sub { $c->json({ waited => 2 }) });
    };

=head1 DESCRIPTION

A L<Future>-compatible asynchronous result. On a live Hyperman worker loop it
is fully non-blocking: timers and continuations run on the loop and the worker
serves other requests while it is pending. Anywhere else (another PSGI server,
a script, the test suite) it degrades to blocking - a timer sleeps, and an
unsettled C<get> is an error, exactly as an off-loop L<Future> is.

A handler may return one: Punk's dispatcher awaits any future-compatible value
(it keys on C<then> / C<on_ready> / C<get>), so returning a C<Punk::Future>
defers the response on the loop and awaits it inline off it.

=head1 CONSTRUCTORS

=head2 new

A new pending future.

=head2 done_future(@values) / fail_future(@failure)

An already-settled future.

=head1 RESOLVING

=head2 done(@values) / fail(@failure)

Settle a pending future; fires its callbacks. A no-op on an already-settled
future. Chainable.

=head2 cancel

Settle a pending future cancelled; its C<on_ready> callbacks and any
then-chain fire, the chain propagating the cancellation onward. Chainable.

=head1 STATE

=head2 is_ready / is_done / is_failed / is_cancelled

=head2 state

Booleans, and the raw settle state.

=head2 failure

The first failure value of a failed future, or undef.

=head1 CALLBACKS

=head2 on_ready($cb)

C<< $cb->($future) >> when it settles, any outcome.

=head2 on_done($cb) / on_fail($cb)

C<< $cb->(@values) >> for the matching outcome. All three fire at once on an
already-settled future and return the future.

=head1 CHAINING

Each returns a new future the callback's result settles; a callback that
returns a future is adopted, so chains compose without nesting.

=head2 then($on_done, $on_fail?)

Map the value on success (and, given C<$on_fail>, recover a failure);
otherwise the failure passes through.

=head2 else($on_fail) / catch($on_fail)

The failure branch only; a success passes through.

=head2 followed_by($cb)

C<< $cb->($future) >> once it settles either way; adopt the future it returns.

=head1 AWAITING

=head2 get / await

C<get> blocks until ready and returns the values (or rethrows the failure);
C<await> blocks and returns the future. On a live loop they pump it; off-loop a
pending future with nothing to settle it is an error (as an off-loop L<Future>
is).

=head1 TIMERS

=head2 timer($secs)

A future that settles after C<$secs> - a loop timer on a live worker, a plain
sleep off it. Also C<< $c->timer >> / C<< $c->after >>.

=head2 defer($cb)

Run C<$cb> on the next loop tick (or now, off-loop); the future settles with
its result.

=head1 COMBINATORS

Each takes a list of futures and returns one.

=head2 needs_all(@futures) / all

Done when all succeed (their values combined in order); fails as soon as any
fails.

=head2 needs_any(@futures) / any

Done on the first success; fails only if all fail.

=head2 wait_all(@futures)

Done when all have settled, whatever the outcome (the futures are the value).

=head2 wait_any(@futures)

Done as soon as any has settled.

=head1 SEE ALSO

L<Punk>, L<Punk::Context/promise>, L<Hyperman/Future>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
