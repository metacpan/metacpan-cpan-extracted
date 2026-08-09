package Punk::Context;

use 5.010;
use strict;
use warnings;
use Punk::Request;
use Punk::Response;
use Punk ();

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Punk::Context - the per-request object

=head1 DESCRIPTION

Every guard, hook, plugin helper and controller receives one argument:
the context. It wraps the PSGI environment lazily and carries the
response builders. See L<Punk> for the framework overview.

The class is entirely XS: storage is array slots and every method is an
XSUB reading them directly, so the context costs nothing per request
beyond its construction.

=head1 METHODS

=head2 env

The raw PSGI environment hashref.

=head2 app

The compiled L<Punk::App>.

=head2 req

The lazy L<Punk::Request>.

=head2 res

The lazy L<Punk::Response> builder - only constructed when used.

=head2 ua

    my $res = $c->ua->get($url)->get;              # blocking

    get '/proxy' => sub {                          # or hand the future back
        my ($c) = @_;
        $c->ua->get($url)->then(sub { $c->json({ got => $_[0]->content }) });
    };

The outbound L<Fetch> agent. Unlike the accessors above this is not per
request: it is one agent per worker, shared by every request that worker
serves, so its keep-alive pool and DNS state survive between them. The context
only memoises the lookup. Configure it with the L<Punk/ua> keyword.

On a L<Hyperman> worker the agent runs on the same event loop serving inbound
requests, so returning its future from a handler lets the worker answer others
while the call is in flight. Anywhere else - a test, a script, C<punk console>
- there is no loop to join, Fetch uses its own, and C<< ->get >> blocks.

Each worker builds its own on first use, so no two share a socket.

With C<< ua cookie_jar => 1 >> this returns a per-request clone carrying its own
jar, over the same pool. The context memoises whichever it is, so calling
C<< $c->ua >> twice in one request gets one agent and one jar. See L<Punk::UA>.

=head2 stash

A per-request hashref for passing values between guards, hooks and the
controller.

=head2 param($name)

Validated OpenAPI parameters first (path, then query), then web route
captures, then the request (query, then form body).

=head2 params

=head2 params(@names)

The same layers, several names at a time. With no names, all of them
merged into one hashref, stacked in that precedence.

With names, only those: a list of values in the order asked for (C<undef>
for a name no layer has) in list context, and in scalar context a hashref
of just the names that were there, so a set of optional filters is one
call rather than a loop -

    my %filter = %{ $c->params(qw(state queue task worker)) };

Note that C<%{ }> is scalar context, but an argument list is not: reach
for C<scalar> where the call sits somewhere already in list context. A
list of names that happens to be empty is the same call as no names, and
so gives everything. See L<Punk::Request/params>, which this defers to
for the last layer.

=head2 openapi

The validated parameter hash from L<Open::API/validate_request> on API
routes; undef elsewhere.

=head2 model($name)

The registered L<Punk::Model> instance (per-worker, built on first
access).

=head2 render($template, \%data, %options)

Render through the app's view engines; returns a finished response.
See L<Punk::Views>.

=head2 json($data, $status?)

=head2 text($body, $status?)

=head2 html($body, $status?)

=head2 redirect($url, $status?)

=head2 not_found

Finished responses. Status and headers previously set through
L</status> and L</header> are folded in.

=head2 status($code)

=head2 header($name => $value)

Set response status / add a response header; chainable. With no
arguments C<status> returns the pending status.

=head2 cookie($name)

=head2 cookie($name => $value, %opts)

With one argument, read a request cookie. With a value, set a C<Set-Cookie> on
the response (an C<undef> value deletes it); options C<path> (default C</>),
C<domain>, C<max_age>, C<secure>, C<httponly>, C<samesite>. The set form
chains.

=head2 session

The signed cookie-backed session hashref (see L<Punk::Session>); requires the
C<session> keyword. Read and write it; it is written back to the cookie at the
end of the request if it changed.

=head2 session_expire

Log out: empty the session and delete its cookie. Chainable.

=head2 upload($name)

The L<Punk::Upload> for a C<multipart/form-data> file field (the first if
several), via C<< $c->req->upload >>.

=head2 log

The request L<Punk::Logger> (cached for the request): C<< $c->log->info(...) >>,
C<debug>, C<warn>, C<error>, C<fatal>. Its lines carry the request's method and
path, and are delivered to the server's C<psgix.logger> when one is present.
Configure with the C<logging> keyword. See L<Punk::Logger>.

=head2 match

Routing information for the matched route (captures, route record).

=head2 promise

A new pending L<Punk::Future> - loop-backed on a live Hyperman worker,
self-contained (blocking) otherwise. Return it (or a C<then> of it) from a
handler to defer the response; settle it later from whatever wakes it.

    get '/wait' => sub {
        my ($c) = @_;
        my $p = $c->promise;
        $c->timer(1)->on_done(sub { $p->done($c->json({ ready => 1 })) });
        return $p;                    # answered when $p is settled
    };

=head2 timer($secs)

=head2 after($secs)

A L<Punk::Future> that settles after C<$secs>: a loop timer on a worker, a
sleep off it. C<< $c->timer(2)->then(sub { ... }) >> answers the request two
seconds later without pinning the worker.

=head2 await($future)

Block until C<$future> is ready and return its values (rethrowing a failure) -
pumping the loop re-entrantly on a worker, blocking off it. The imperative
escape hatch; C<< return $future >> is the non-blocking way.

=head2 stash_hv

=head2 openapi_params

The raw storage slots behind L</stash> and L</openapi>, read or written
directly (the accessor pair the class is built from). Prefer C<stash>
and C<openapi>, which lazily build and coerce; these exist for the
framework and for code that wants the slot untouched.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
