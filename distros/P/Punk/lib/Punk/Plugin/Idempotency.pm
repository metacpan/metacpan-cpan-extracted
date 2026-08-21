package Punk::Plugin::Idempotency;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';

1;

__END__

=head1 NAME

Punk::Plugin::Idempotency - Idempotency on unsafe methods

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    cache 'file', dir => '/var/cache/app';

    plugin 'Idempotency' => {
        scope => sub { $_[0]->current_user->{id} },
        ttl   => 86400,
    };

    post '/orders' => sub { ... }, { idempotent => 1 };

=head1 DESCRIPTION

A client that sends C<POST /orders> and loses the connection cannot know
whether the order was created. It has two choices and both are bad: retry
and risk two orders, or give up and risk none. An C<Idempotency-Key>
removes the choice - the server recognises the retry and replays the
first response.

=head2 What this guarantees, and what it does not

A retry carrying the same key, B<within the TTL>, that reaches a worker
able to see the store, B<after the first request's response was
recorded>, replays that response instead of executing the work again.

Every clause there is load-bearing, and the last one is a window.
Between the handler committing the order and the entry reaching the
store, this plugin provides nothing: a process killed in that gap leaves
an order created and no key recorded, so the retry executes and creates
a second one - the exact failure the plugin exists to prevent, in the one
situation where a client is most likely to retry.

B<Cache-backed idempotency collapses that window. It does not remove
it.> On this machine the gap is about three microseconds - the
after-dispatch chain plus one store write - so the process has to die
inside a three-microsecond window that occurs once per idempotent
request. That is a risk an operator can reason about, which is why it is
a number here rather than an adjective.

Two things widen it, and both are yours: a slow store, and anything you
add to the after-dispatch chain, because every hook there runs inside the
gap.

Closing it entirely needs the key written B<inside the same transaction
as the work>, which means the store has to be the database - and this
plugin does not own your handler's transaction. See L</The store is a
seam> for what that would take.

=head2 The scope is yours, and there is no default

    plugin 'Idempotency' => { scope => sub { $_[0]->current_user->{id} } };

Required. The plugin croaks at boot without it.

The stored value is a B<whole response> - somebody's order, with their
address in it. If two accounts can produce the same cache key, this
plugin becomes a way to read other people's responses by guessing a
UUID, on exactly the endpoints worth reading. Scoping it is the thing
that prevents that, and the plugin cannot do it for you: a Punk
application may authenticate through a session, an C<auth> identity, an
OAuth2 token or an API key, and picking one would be silently wrong for
the rest.

Whatever the coderef returns is the scope. Returning C<undef> means the
plugin cannot say whose key this is, and it will not invent an answer:
B<the request proceeds as though the plugin were not there>, nothing is
stored, and a warning is logged. An application that wants idempotency
for anonymous callers - a signup, a payment carrying its own token -
returns something itself, which puts that decision with the person able
to make it safely.

=head2 What a key is scoped to

Three things, and each has a reason:

=over 4

=item * B<The scope>, above.

=item * B<The route, as declared> - C</orders/:id>, not C</orders/7> - so
the same key against two endpoints does not replay one endpoint's answer
for the other. The method is in there with it, because C<POST /orders>
and C<DELETE /orders> are different operations a client could reasonably
key the same way.

=item * B<The request itself.> The entry records a fingerprint - the
method, the route and the body - and a retry whose fingerprint does not
match gets a C<422>. A key reused with a different body is a client bug,
and a silent replay is the worst possible answer to it: the client would
believe its second, different order had succeeded when it never ran.

=back

=head2 The key is request bytes

C<Idempotency-Key> must be 1 to 255 printable ASCII characters with no
space. Anything else is a C<400>, B<refused rather than repaired> -
trimming a bad key into a good one means two different client keys can
become one server key, which is the collision all of the above exists to
prevent. The key is hashed before it reaches the store, so no input
reaches a cache key, let alone a path.

=head2 Which responses are replayed

C<2xx>, C<3xx> and C<4xx> are recorded. B<C<5xx> is not>: a C<5xx> is
transient by construction, and replaying one turns a single bad minute
into a permanent bad day for the life of the TTL - the client retries,
gets the stored C<500> instantly, retries again, and the endpoint is
broken for that key until it expires. A C<4xx> B<is> recorded, because a
C<422> for a malformed order is a real answer about that request.

A response whose body is not an arrayref of strings - a C<send_file>, a
stream - cannot be recorded without consuming what is being sent, so it
is served normally and B<not> recorded. That means no idempotency on that
request, so it is logged at warn.

A replay carries C<Idempotency-Replayed: true>. A client that cannot tell
a replay from a fresh execution cannot debug anything, and neither can
your log.

A stored C<Set-Cookie> is B<not> replayed - the one deliberate exception
to "return what they got". That cookie carries the first request's
session state, and handing it to a retry that may arrive from a newer
session writes back a stale one.

=head2 Guards run first

The replay happens between a route's guards and its handler, never
before them. A replay returns a stored response B<body>, so answering
ahead of the guards would hand somebody else's order to a caller the
guard was about to refuse. An unauthorised retry carrying a perfectly
valid key gets your guard's answer.

=head2 Two retries at once

A client whose connection dropped often retries more than once.
L<Punk::Cache>'s single-flight lock is what makes that safe: the first
execution holds it, and a concurrent retry waits and replays rather than
executing in parallel. A retry that waits out the budget executes anyway
- a stalled request is worse than a duplicated one, which is the rule
C<compute> already follows.

The plugin reads B<through the memory tier, never from it>. A tier is a
copy per worker, eventually consistent, and a tier that has not yet seen
a write answers "no entry" - which here means "execute the work a second
time". So C<< memory => ... >> on your cache is honoured for everything
else and bypassed for these keys.

=head2 The store is a seam

Everything above reaches the store through three operations: read, write
with a TTL, and a best-effort lock. Any L<Punk::Cache> backend works,
including one from outside this distribution.

That is deliberate. A database-backed store - the thing that would close
the window, by writing the key inside your transaction - implements those
same three, so it is a drop-in rather than a rewrite of this plugin.

=head1 OPTIONS

=over 4

=item scope

Required, a coderef receiving the context. See above.

=item ttl

Seconds an entry is replayable, default C<86400>. How long after a failed
request will your client still retry is a business question, so this is
an option rather than a constant.

=back

=head1 ROUTE OPTIONS

C<< idempotent => 1 >> opts a route in. It is per route because a key
honoured on every C<POST> means a store write on every C<POST>, and most
C<POST>s do not need one. Inert unless this plugin is registered; on a
route that never receives a key it costs about 26 nanoseconds.

Only C<POST>, C<PUT>, C<PATCH> and C<DELETE> are affected. C<GET> is
already idempotent, and caching it is L<Punk::Cache> or
L<Punk::Plugin::ConditionalGet>.

A request with no C<Idempotency-Key> proceeds normally. Requiring one is
an API design decision you make in a guard, not one a plugin imposes.

=head1 SEE ALSO

L<Punk>, L<Punk::Cache> for the store and its single-flight lock,
L<Punk::Queue> for work that must not be lost rather than merely not
repeated.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
