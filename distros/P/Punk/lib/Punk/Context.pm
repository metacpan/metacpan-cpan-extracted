package Punk::Context;

use 5.010;
use strict;
use warnings;
use Punk::Request;
use Punk::Response;
use Punk ();

our $VERSION = '0.27';

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

C<redirect> sends where it is told. When the destination came out of the
request, put it through L</safe_path> first.

=head2 safe_path($path, $fallback?)

    $c->redirect($c->safe_path($c->param('to'), '/'));

Returns C<$path> when it is a same-origin relative path, and C<$fallback>
(C<undef> by default) when it is not. This is the guard for a redirect target
the request supplied - C<?to=>, C<?return=>, C<?next=> - which is otherwise
an open redirect: an attacker sends a victim to your login page with
C<?to=//evil.example>, and your own site bounces them somewhere else once
they authenticate.

A path passes only if it starts with C</>, does not start with C<//>, and
contains no C0 control byte, no C<DEL>, and no backslash. The last two rules
are blunter than they look necessary, because a browser does not read the
string the way this check does: it removes every TAB, CR and LF from a URL
before parsing it, so C<"/\tevil.example"> reaches it as C<"//evil.example">,
and under a special scheme it treats C<\> as C</>. Both leave the site while
passing a naive "starts with a slash" test. A path that genuinely wants one
of these characters percent-encodes it.

C<auth_guard> hands you exactly such a parameter when it redirects to
C<login_path> with C<?to=>, so a login form that honours it wants this.
These are the same rules as L<Punk::OAuth2>'s C<same_origin_path>, which is
where they were learned: CVE-2026-75628.

=head2 send_file($source, %options)

    get '/invoice/:id' => sub {
        my $c = shift;
        return $c->send_file("/var/store/$id.pdf",
            filename => "invoice-$id.pdf");
    };

    # bytes already in memory (a generated document)
    return $c->send_file(\$pdf_bytes, type => 'application/pdf');

A finished download response, returned by the handler like any other.
The source is a file path or a reference to a scalar of bytes. The whole
download story is handled here: C<ETag> (strong, from mtime and size) and
C<Last-Modified> with C<304> answers to C<If-None-Match> /
C<If-Modified-Since>; a single byte C<Range> served as C<206> with
C<Content-Range> (C<416> when unsatisfiable, and a multi-range or
malformed header is legally answered with the full C<200>); C<If-Range>
honoured on an exact validator match; C<HEAD> answered with the real
headers and no body. Headers previously set through L</header> are
folded in. Ranged file bodies ride L<Punk::SendFile::Reader>, so no more
than 64KB of the file is in memory at once; a full-file body is a plain
filehandle the server streams.

Options: C<type> (Content-Type; otherwise inferred from the path or
C<filename> extension, else C<application/octet-stream>), C<filename>
(sets C<Content-Disposition: attachment> with the name, RFC 5987-encoded
when it is not ASCII), C<inline> (disposition C<inline> instead),
C<ranges =E<gt> 0> (ignore C<Range> and stop advertising
C<Accept-Ranges>), C<mtime> / C<etag> (override the validators; C<mtime>
is what gives a scalar source one), C<cache_control> (a freshness
lifetime, sent on the C<304> as well as the C<200> - a C<304> that
omitted it would leave the stored copy with the lifetime that has just
run out), and C<missing =E<gt> 'not_found'> (answer the house 404 for an
unreadable path instead of croaking).

The path is served as given - if any part of it came from the request,
the traversal guard is yours.

=head2 asset($url)

The content-addressed URL for a file under a C<< static ... fingerprint
=> 1 >> mount: C</static/app.css> becomes
C</static/app.9f3a1c2b0d4e5f60.css>, which serves with a year and
C<immutable> because that URL cannot come to mean anything else. A URL
under no static mount, under one that has not opted in, or naming a file
that cannot be read comes back exactly as it went in - so a template can
be written against this before the mount asks for it. See
L<Punk::Static/Freshness>.

=head2 respond_to(%format_handlers)

    return $c->respond_to(
        json => sub { $_[0]->json({ book => $book }) },
        html => sub { $_[0]->render('book/view', { book => $book }) },
        any  => sub { $_[0]->text('book', 200) },
    );

Accept negotiation: calls the handler for the most acceptable offered
format and returns its response. Formats are C<json>, C<html>, C<text>,
C<xml> or any full media type (C<'application/vnd.book+json'>); q-values
order the choice and C<q=0> excludes. A client that expressed no
preference - no C<Accept>, or only a wildcard match - gets the format its
own request Content-Type names when that is offered, else the first
registered. When nothing fits, the C<any> handler is called if given;
otherwise the response is a C<406>. Every outcome carries C<Vary: Accept>.

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

The session hashref (see L<Punk::Session>); requires the C<session> keyword.
Read and write it; it is written back at the end of the request if it changed -
to the cookie, or to the store when one is configured.

=head2 session_expire

Log out: empty the session and delete its cookie. With a store it also deletes
the entry, so the session is revoked rather than merely dropped by the browser
in front of you. Chainable.

=head2 session_rotate

    post '/login' => sub {
        my ($c) = @_;
        ...
        $c->session_rotate;                 # a new id, the same session
        $c->session->{user_id} = $user->id;
        $c->redirect('/');
    };

Keep the session, give it a new id, and delete the entry under the old one.
Chainable.

Call it at the privilege boundary, which is a login or an elevation, and
nowhere else. Session fixation is the attack it prevents: somebody plants a
known id in a victim's browser and waits for them to log in, and if logging in
writes the user into the session the attacker planted, the attacker's id is now
an authenticated session.

Without a store this is a no-op, and deliberately so rather than an error: a
cookie session's value changes wholesale when its contents do, so there is
nothing to rotate. Saying that out loud matters, because an application may be
written against the cookie session and later given a store.

=head2 flash

    $c->flash(notice => 'Saved.');      # set, for the NEXT request
    my $note = $c->flash('notice');     # read this request's inbound
    my $all  = $c->flash;               # the whole inbound hashref

One-request messages over the session (requires the C<session> keyword):
set with pairs (chainable), read by key, or take the whole inbound
hashref for a template. See L<Punk::Session/FLASH> for the lifecycle.

=head2 flash_keep

Re-arm this request's inbound flash for one more request. Chainable.

=head2 validate($schema?, $data?)

    my $v = $c->validate(\%json_schema);    # run a validation now
    return $c->json({ errors => $v->errors }, 400) if $v->has_errors;

    my $v = $c->validate;                   # no args: the last Result

Collecting request validation - never croaks on invalid data. With a
schema, runs: C<$data> defaults to the decoded JSON body for a JSON
request, the merged params otherwise; returns a L<Punk::Validate>
Result. With no arguments, reads: the last Result this request produced
(a route-level C<validate> option ran before the handler), or undef.

=head2 login($user_or_id)

=head2 logout

=head2 auth_id

=head2 current_user

=head2 check_password($user, $password)

=head2 issue_token($user_id, $kind, $ttl)

=head2 take_token($token, @kinds)

The authentication battery's surface; all need the C<auth> keyword.
C<login> records the identity in the session and C<logout> expires it;
C<auth_id> is the raw session id, C<current_user> the row loaded once per
request through the configured model. C<check_password> burns the same
PBKDF2 work when there is no user or hash, so login timing reveals
nothing. The token pair mints and spends single-use email tokens -
spending deletes first, then validates. See L<Punk::Auth>.

=head2 upload($name)

The L<Punk::Upload> for a C<multipart/form-data> file field (the first if
several), via C<< $c->req->upload >>.

=head2 log

The request L<Punk::Logger> (cached for the request): C<< $c->log->info(...) >>,
C<debug>, C<warn>, C<error>, C<fatal>. Its lines carry the request's method and
path, and are delivered to the server's C<psgix.logger> when one is present.
Configure with the C<logging> keyword. See L<Punk::Logger>.

=head2 match

Routing information for the matched route:

=over 4

=item * C<captures> - the path captures, as a hashref.

=item * C<route> - the matched route record. Its C<path> is the route as
B<declared> (C<"/users/:id">, not C<"/users/7">), and its C<method> the verb it
was declared under. Absent for a 404, a 405, anything answered by a mount, and
inside a L<Punk/before_request> hook, none of which have a route to name.

=item * C<operation> - the C<operationId>, for a request answered by an C<api>
mount. A route record and an operation are mutually exclusive.

=back

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
