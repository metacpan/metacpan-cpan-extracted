package Punk::Context;

use 5.010;
use strict;
use warnings;
use Punk::Request;
use Punk::Response;
use Punk ();

our $VERSION = '0.48';

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

=head2 txn($code) / txn($database => $code)

    my $order = $c->txn(sub {
        my ($tx) = @_;
        my $o = $tx->model('Order')->create(\%data);
        $tx->model('Stock')->update({ id => $sku, held => $held + 1 });
        return $o;
    });
    $c->txn(analytics => sub { ... });

A transaction on the default database, or the one the C<database> keyword
named. The block receives a L<Punk::Txn>; C<< $tx->model($name) >> is the
model bound to the transaction, and a model on another database croaks.
Returns what the block returns: on L<Punk::Model::DBI> the value, after
commit; on L<Punk::Model::DBIx::Loop> a L<Punk::Future> of it, resolved
after commit - return that from the handler. A die inside the block rolls
back and rethrows. What C<< $tx->model >> means on each backend, and why
it differs, is in L<Punk::Txn>.

=head2 render($template, \%data, %options)

Render through the app's view engines; returns a finished response.
Options: C<status>, C<type>, C<engine>, and C<layout> - a wrapper template
name, or C<undef> for none:

    return $c->render('book/view', { book => $book });               # the page
    return $c->render('book/_row', { book => $book }, layout => undef); # a piece of one
    return $c->render('mail/reset', \%data, layout => 'mail');         # other chrome

An option not in that list croaks rather than being skipped. See
L<Punk::Views>.

=head2 fragment($template, \%data?, %options)

    return $c->fragment('console/_panel', { rows => $rows });

C<render> with C<< layout => undef >> and C<< Cache-Control: private,
no-store >> on the response - one header, replacing any Cache-Control
already pending on the context. The other render options pass through;
C<layout> croaks, since a fragment with a layout is a page.

The header is the default because a fragment is almost always one user's
data swapped into one user's page, and a shared cache handing it to the
next visitor is a leak. The public, cacheable partial - a product card, a
footer - is C<< render(..., layout => undef) >> with a C<Cache-Control>
of your own.

=head2 json($data, $status?)

=head2 xml($doc, $status?)

=head2 text($body, $status?)

=head2 html($body, $status?)

=head2 redirect($url, $status?)

=head2 not_found

Finished responses. Status and headers previously set through
L</status> and L</header> are folded in.

C<xml> takes a L<File::Raw::XML::Document>, a L<File::Raw::XML::Node> or a
string of markup you built yourself, and answers C<application/xml;
charset=utf-8>. A document is written with its XML declaration, a node
without one, because a node is a fragment. Any other reference is refused
rather than stringified. Returning a document from a handler does the same
thing without the call, and so does returning one from a
L</respond_to> branch.

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

=head2 stream($content_type, $cb) / stream($content_type, \%opts, $cb)

    get '/export' => sub {
        my $c = shift;
        $c->stream('text/csv', sub {
            my ($c, $w) = @_;
            while (my $chunk = $rows->next_chunk) {
                $w->write($chunk);
                my ($ok) = $c->await($w->drain);
                return unless $ok;
            }
        });
    };

A response body of unknown length, emitted as it is produced - the
handler returns what C<stream> returns. The callback gets the context
and a writer; C<< $w->drain >> is the backpressure future. Bytes never
accumulate beyond one chunk, and on a Hyperman worker the await keeps
serving other requests. The whole story - the three transports, chunked
framing, how a die differs from a clean end, and every option - is
L<Punk::Stream>. For a body that already exists as a file or a scalar,
L</send_file> is the finished version of this.

=head2 origin

    my $base = $c->origin;            # 'https://acme.example.com'

The request's scheme and host, when that host is the application's
declared L<Punk/host> or matches its C<allow> list; the canonical origin
when it is anything else; C<undef> when no C<host> was declared. Never
the raw C<Host> header, so the value can be joined onto and reflected -
in a sitemap, a redirect, a link in a mail - without handing a client the
power to choose it. Honours the L<Punk/proxy> keyword, since it reads the
same resolved environment. No path: C<< $app->host >> keeps one if it was
declared with one, this is the origin in the browser's sense.

=head2 url_for($name, %args)

    $c->url_for('books');                          # /books
    $c->url_for('book', id => 42);                 # /books/42
    $c->url_for('book', id => 42, page => 2);      # /books/42?page=2
    $c->url_for('book', id => 42, absolute => 1);  # https://example.com/books/42
    $c->url_for('file', path => 'a/b.txt');        # a *splat keeps its slashes

The URL of a route declared with C<< { name => ... } >>, so nothing has to
spell its path twice. See L<Punk/Named routes> for the rules and
L<Punk::View::Stencil/Named routes> for the template forms.

An argument naming a capture fills that segment; anything left over becomes
the query string, keys sorted, C<undef> giving a bare key and an arrayref
repeating one. Two argument names are reserved rather than captures:

=over 4

=item * C<< absolute => 1 >> prefixes L</origin>, and croaks when no
L<Punk/host> was declared rather than taking the value from the request.

=item * C<< query => \%h >> is the explicit query hash, for a query key
spelled like a capture. With it, an argument that names no capture croaks
instead of becoming a query pair.

=back

The result carries the application's prefix - the path on L<Punk/host>,
then C<SCRIPT_NAME> - whether or not it is absolute.

It croaks rather than return a URL that cannot work: on a name no route
carries, on a capture with no value, on an empty one, on a reference, and
on a C</> inside a C<:param>, which C<PATH_INFO> would deliver decoded and
split into an extra segment. Those are bugs at the call site, and a 500 in
development is how they get found; L<Punk::Test> takes C<< [ 'book', id =>
1 ] >> wherever it takes a path, which turns a wrong name into a failing
test rather than a 404 in production.

=head2 host_allowed

True when the request's C<Host> is one the application declared: the
canonical host, or a match on the allowlist. The signal for an application
that would rather answer C<421> to an unknown host than serve the canonical
site under a name it does not own.

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
C<domain>, C<max_age>, C<secure>, C<httponly>, C<samesite>, C<signed>. The
options may also be given as one trailing hashref; the set form chains.

=head3 Signed cookies

    $c->cookie(theme => 'dark', { signed => 1, max_age => 31536000 });

    my $theme = $c->cookie('theme', { signed => 1 });

B<Signed is not secret.> The value is readable by anyone who holds the
cookie; the signature only proves this server wrote it and that nobody
changed it since. A value that must be unreadable does not belong in a
cookie at all - it belongs in the session, whose store keeps it
server-side.

What signing buys is tamper evidence without the session's lifetime or
write pattern: a remember-me selector, an A/B assignment, a "seen the
banner" flag that must not be forgeable into someone else's. Reading
with C<< signed => 1 >> verifies (in constant time) and returns the
value, or returns C<undef> - an unsigned, tampered or swapped cookie
fails exactly as a missing one does, and never croaks, because the
input is the network's. The cookie's B<name is under the signature>, so
two signed cookies cannot be swapped for each other by the client.

The key is the C<session> keyword's C<secret> - the machinery and the
key path are the session's own, so there is nothing new to configure or
rotate; asking for a signed cookie without a configured session croaks.
Reading a signed cookie without the option returns the raw signed form
(two base64url runs joined by a dot), not the value.

The signature costs about 43 bytes on the wire per cookie, plus the
base64url expansion of the value itself, against a browser's ~4KB
budget per cookie - nothing enforced, but worth knowing before signing
something large.

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

"A JSON request" means one whose Content-Type is C<application/json>, and
nothing else is treated as a body. A schema on a route that receives XML
therefore validates the merged params - the query string - and reports
success over a body it never looked at. JSON Schema describes Perl data,
which a document tree is not, so there is no C<xml> source to name; pass
C<$data> yourself, built from the tree, when a route takes XML and must be
validated.

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

=head2 after_response($code)

    $c->after_response(sub {
        my ($c, $resp) = @_;
        $c->model('Audit')->create({ status => $resp->[0] });
    });

Run C<$code> once this response has been handed to the server - the work the
request generates but the client is not waiting for. It is given the context
and the response that was sent; a return value is discarded, and a die is
logged while any callbacks after it still run.

Queue as many as you like; they run in registration order, after the
application's own C<after_response> hooks. Chainable.

On a L<Hyperman> worker this runs on the next pass of the event loop, and on
a C<psgix.cleanup> server the server runs it; anywhere else it runs inline,
just before the response is returned. See L<Punk/after_response> for what
that means and for why this is not a job queue.

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
