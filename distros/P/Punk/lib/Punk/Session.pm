package Punk::Session;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';

1;

__END__

=head1 NAME

Punk::Session - signed cookie sessions

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    session
        secret   => secret('session_key'),   # from the secrets system
        expires  => '7d',
        samesite => 'Lax';

    post '/login' => sub {
        my ($c) = @_;
        $c->session->{user_id} = $user->id;   # signed into the cookie
        $c->redirect('/');
    };

    get '/me' => sub {
        my ($c) = @_;
        my $id = $c->session->{user_id} or return $c->redirect('/login');
        $c->json({ id => $id });
    };

    post '/logout' => sub { my ($c) = @_; $c->session_expire; $c->redirect('/') };

=head1 DESCRIPTION

A session is a hashref carried in a cookie: the handler reads and writes
C<< $c->session >>, and at the end of the request Punk serializes it (JSON),
signs it with HMAC-SHA256 and the configured secret, and sets the cookie - only
when it actually changed. The client can read the contents but cannot forge
them, so do not put secrets in a session; a tampered cookie is rejected and the
session comes up empty.

"Cannot forge them" is exactly as true as the secret is, which is why there is
no default for it and no way to start without one. See L</"THE KEYWORD">.

The whole session lives in the cookie, which is why it is capped: one that
serializes over ~4KB croaks. Both of those are the cookie's properties rather
than the session's - C<< store => ... >> moves the payload to a server-side
store, leaves an opaque id in the cookie, and takes the ceiling with it. See
L<Punk::Session::Store>, and L</store> below.

=head1 THE KEYWORD

    session secret => secret('key'), expires => '7d', secure => 1;

Enables sessions for the application. Options:

=over 4

=item * C<secret> - the signing key. B<Required>, and required to be
non-empty: C<session> croaks at boot without one rather than starting, because
the alternative is signing with a zero-length HMAC key, which anybody who
knows the cookie format can reproduce offline. Source it from the
L<secrets system|Punk/secret> so it never sits in the code - and because
C<secret> itself fails closed, an unset environment variable or a missing
config path becomes a startup error rather than a forgeable cookie.

=item * C<cookie> - the cookie name (default C<punk.sid>).

=item * C<expires> - a lifetime like C<'7d'> / C<'12h'> / C<'30m'> / seconds;
omitted means a session cookie (gone when the browser closes).

This is a real lifetime, not just a C<Max-Age>: the expiry is stamped inside
the signed payload and checked when the cookie is read, so a cookie past it
is refused whatever the client chose to keep. A cookie with no C<expires> is
still bounded, at 30 days - "until the browser closes" is a promise the
client makes, not a limit on how long the value stays good. The stamp
refreshes every time the session is written, so an active session does not
expire out from under someone.

=item * C<path> (default C</>), C<domain>, C<secure>, C<httponly> (default on),
C<samesite> (default C<Lax>) - the cookie attributes.

=item * C<store> - keep the session server-side, with only an id in the cookie.
See L</store>.

=item * C<sliding>, C<tier>, C<allow_unshared> - the store's options, and
meaningless without it. See L<Punk::Session::Store>.

=back

An option the keyword does not understand is a boot croak naming it. It used to
be copied into the config verbatim, so a misspelt C<httponly> looked configured
and was not - survivable while every option was a cookie attribute with a safe
default, and not survivable for C<store>, where the typo's failure is
"everything works and the store stays empty".

It also reads from C<config/punk.yml> under a C<session:> block.

=head2 store

    cache 'file', dir => '/var/cache/app';
    session secret => secret('session_key'), expires => '7d', store => 'cache';

Moves the payload off the client. The cookie carries a signed 128-bit id and
the session lives in a L<Punk::Cache> store - the default one, a store C<cache>
declared, a hashref describing one, or a store object. Any backend that
satisfies that contract will do, including one from outside this distribution,
so sessions in Redis or in your database are a store somebody writes once.

C<< $c->session >> does not change. What changes is that the ~4KB ceiling goes,
the client can no longer read the contents, and C<< $c->session_expire >>
revokes rather than merely asking the browser to forget.

The store is resolved at boot, and one that is not shared between workers is
refused there - it would be a logout at random, once per request that landed on
another worker.

L<Punk::Session::Store> is the whole of it: the four forms, what it costs, the
pool, rotation, and the sliding expiry.

=head1 CONTEXT METHODS

=head2 session

The session hashref. Read and write it; it is written back to the cookie at the
end of the request if it changed.

=head2 session_expire

Log out: empty the session and delete the cookie.

B<Without a store, be clear about what that can and cannot do.> It tells the
browser in front of you to drop the value; it cannot reach a copy someone
already took, because there is no server-side record of the session to mark
dead - the cookie B<is> the session. A stolen cookie therefore stays good until
its stamped expiry runs out, which is the ceiling C<expires> sets and the
reason it is enforced server-side rather than left to C<Max-Age>.

B<With a store it deletes the entry>, and a copy someone took is dead on its
next request. That is the difference L</store> buys, and the reason it exists.

Neither revokes every session a user has - a second browser, a phone. That
needs to enumerate them, which the store contract deliberately cannot do: keep
a per-user token or counter in your own table and check it in a guard.

=head2 session_rotate

Give the session a new id and delete the entry under the old one. Call it when
privilege changes, which means a login. Without a store it is a no-op. See
L<Punk::Context/session_rotate> for the fixation attack it prevents.

=head2 flash

=head2 flash_keep

One-request messages riding the session - see L</FLASH>.

=head1 FLASH

    post '/save' => sub {
        my ($c) = @_;
        $c->flash(notice => 'Saved.');       # for the NEXT request
        $c->redirect('/list');
    };

    get '/list' => sub {
        my ($c) = @_;
        $c->render('list', { flash => $c->flash });
    };

A flash message lives exactly one request: set it, redirect, and the
redirected-to page reads it once. It rides the session under one reserved
key (C<punk.flash>), so it shares the session's machinery - the signing,
the change-detected write-back, and the ~4KB cap - and needs the
C<session> keyword configured.

C<< $c->flash(key => $value, ...) >> sets messages for the next request;
C<< $c->flash('key') >> reads one of this request's inbound messages; a
bare C<< $c->flash >> returns the whole inbound hashref (possibly empty) -
which is also how a template gets it, passed explicitly like any other
render data. C<< $c->flash_keep >> re-arms the inbound messages for one
more request - the redirect-through-a-redirect case.

The rotation is the session's own change detection: the first flash call
of a request moves the inbound hash out of the session, so the consuming
response rewrites the cookie without it, while a request that never
touches flash leaves it riding untouched. Setting and reading in the same
request do not meet: reads see the previous request's messages, writes
feed the next one's.

=head1 SEE ALSO

L<Punk::Session::Store> for keeping the session server-side. L<Punk>,
L<Punk::Context/cookie>, L<Punk/secret>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
