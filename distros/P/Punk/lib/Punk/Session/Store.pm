package Punk::Session::Store;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Session::Store - server-side sessions, on any store

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    cache 'file', dir => '/var/cache/app';

    session secret  => secret('session_key'),
            expires => '7d',
            store   => 'cache';               # the payload moves off the client

    post '/login' => sub {
        my ($c) = @_;
        my $user = authenticate($c) or return $c->redirect('/login');
        $c->session_rotate;                   # a new id at the privilege change
        $c->session->{user_id} = $user->{id};
        $c->redirect('/');
    };

    post '/logout' => sub {
        my ($c) = @_;
        $c->session_expire;                   # deletes the entry: revoked
        $c->redirect('/');
    };

=head1 DESCRIPTION

C<< store => ... >> on the L<session|Punk::Session> keyword moves the session
off the client. The cookie carries a signed 128-bit id and nothing else; the
session itself lives in a L<Punk::Cache> store.

C<< $c->session >> is unchanged, so no application code moves.

Three things follow from the payload being server-side:

=over 4

=item * B<The ~4KB ceiling goes.> A session with a basket in it stops being a
croak.

=item * B<"Do not put secrets in a session" stops being true.> The client can
read a cookie session; signed is not sealed. Server-side it can read an opaque
id.

=item * B<Logout can revoke.> A signed cookie is valid until it expires no
matter what the server thinks. An entry can be deleted.

=back

=head1 THE STORE IS A SEAM

Any L<Punk::Cache> backend can hold a session, including one from outside this
distribution. That is the point of putting sessions on that contract rather
than inventing a second one: a Redis or DBI store implements C<get>, C<set>,
C<delete>, C<clear> and C<stats> because it already had to, so one module
serves C<cache>, L<Punk::Plugin::Idempotency> and this.

C<store> takes four forms, told apart by what the value B<is> rather than by
reading a string and guessing:

    session ..., store => 'cache';                  # the default store
    session ..., store => 'sessions';               # one `cache` declared
    session ..., store => { backend => 'Redis::Store', server => '...' };
    session ..., store => $object;                  # a ready-made one

C<'cache'> is reserved for the default store, because that is what an
application with one store calls it; a store genuinely declared under that name
is a boot error naming the collision. Any other string is the name of a store
C<cache> declared, and one that was never declared croaks - a session store
that silently never hits looks like a login page that forgets everybody. A
hashref is built here, in the shape the C<cache> keyword already takes for a
named store. An object is checked against the contract like any other backend.

Writing a backend is L<Punk::Cache/"Writing your own">, and
C<t/lib/PCConform.pm> takes a factory, so a store from outside this
distribution answers the same assertions the shipped ones do. That is worth
doing here more than anywhere: the failure mode of a disagreement is not a low
hit rate, it is somebody logged out.

=head2 What a store owes a session

Four things, beyond the five methods:

=over 4

=item * B<Values are bytes.> The session is JSON before it reaches the store.

=item * B<A key is bytes and never becomes a path.> The file store guarantees
it by hashing; a store from elsewhere guarantees it itself.

=item * B<C<get> returns undef for absent and for expired>, and a C<$ttl> of 0
means no expiry rather than expire immediately. Backwards, that logs out the
whole application at once.

=item * B<C<is_shared> must return true.> Leaving it out means unshared, which
is the safe default for a cache and a boot croak here - see below.

=back

=head2 A session has a ceiling still

A megabyte, rather than the cookie's four kilobytes. Unbounded is not what
replaces a ceiling, because a session an application can grow without limit is
a way to fill a store from a login form. Over it, the session is not saved and
the write-back warns with both numbers.

A store may also refuse a write of its own accord - the file store refuses a
value too large for its budget rather than evicting everything else to fit. A
refusal is warned about rather than swallowed: a login that appeared to work
and did not is the failure this most needs to be loud about.

=head1 THE POOL

A session belongs to the pool, not to the worker that created it, so B<the
store has to be shared between workers>. One that is not is refused at boot:

    Punk: the session store reports that it is not shared between workers ...

Because the alternative is not staleness. The session written on worker A is
B<absent> on worker B, so the user is logged out on whichever request the pool
sends elsewhere, at random, forever. C<< allow_unshared => 1 >> says there is
only one process, which is a thing only the person deploying knows - a test
suite, C<punk dev>, a single-worker deployment.

=head2 The memory tier

L<Punk::Cache>'s C<memory> option puts a per-worker copy in front of a shared
store. B<Sessions go round it by default>, whatever the store is configured
with, because for a session that copy is a bound on how long a B<revoked
session keeps working>: a worker that missed the invalidation answers from its
own copy, and the copy it answers with is the session before the logout.

Be accurate about the other direction, because the loose version of this
argument is wrong: a tier miss falls through to the store, so a tier can never
manufacture a B<missing> session. The hazard runs one way, and it is
authentication staleness.

Opt in when the arithmetic earns it - a network store, and sessions are the
most read-mostly thing an application has:

    cache 'file', dir => '/var/cache/app', memory => '32M', memory_ttl => 2;
    session ..., store => 'cache', tier => 2;

The number is how many seconds you accept a revocation lagging by. It is capped
at 5, the store must actually have a tier, and the store's C<memory_ttl> must
not exceed it - all three are boot errors naming both numbers, rather than a
quiet decision to use the larger one.

Writes are never routed around the tier: C<set> and C<delete> on the store drop
this worker's copy and publish an invalidation so the others drop theirs.

=head1 ROTATION

    $c->session_rotate;

Keep the session, give it a new id, delete the entry under the old one. Call it
at the privilege boundary - a login, an elevation - and nowhere else.

B<This is the one that gets missed.> Session fixation: an attacker plants a
known id in a victim's browser and waits for them to log in. If logging in
writes the user into the session the attacker planted, the attacker's id is now
an authenticated session. A cookie session is immune by accident, because its
value changes wholesale when its contents do. A stored session is not - the id
survives the login unless something changes it.

It cannot be automatic, and the candidates for guessing it are all wrong:
rotating whenever the session gains a key rotates on a shopping basket,
rotating on every C<POST> is a store write per form submission, and watching for
a key named C<user_id> is a convention nobody agreed to. So it is a call the
application makes, at the one place that knows.

Without a store it is a documented no-op rather than an error, because there is
nothing to rotate.

=head1 SLIDING EXPIRY

    session ..., store => 'cache', expires => '7d', sliding => 1;

Off by default, in which case a session expires a fixed period after it was
created - which is what a cookie session does when nothing writes to it.

On, a session in use is extended, and the extension is B<throttled>: it happens
once the session is past half its lifetime, not on every request. Sliding on
every request would be a store write per request, which is the cost the
read-on-demand path exists to avoid. The cookie is reissued along with the
entry, because a cookie that ran out while its entry lived would be exactly the
logout sliding exists to prevent.

=head1 SEE ALSO

L<Punk::Session> for the keyword, the cookie and C<flash>; L<Punk::Cache> for
the store contract and for writing a backend; L<Punk::Context/session_rotate>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
