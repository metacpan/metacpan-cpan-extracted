package PAGI::Response;
$PAGI::Response::VERSION = '0.002001';
use strict;
use warnings;

use Future::AsyncAwait;
use Carp qw(croak);
use Encode qw(encode FB_CROAK);
use JSON::MaybeXS ();
use PAGI::Headers ();


=encoding UTF-8

=head1 NAME

PAGI::Response - Fluent response builder for PAGI applications

=head1 SYNOPSIS

    use PAGI::Response;
    use Future::AsyncAwait;

    # A response is a VALUE: build it, then send it (or return it, or mount it).

    # Raw PAGI app: build the value, send it with respond($send)
    async sub app ($scope, $receive, $send) {
        my $res = PAGI::Response->new($scope);   # detached -- no connection
        await $res->status(200)
                  ->header('X-Custom' => 'value')
                  ->json({ message => 'Hello' })      # sets the body, returns $self
                  ->respond($send);                   # the single send step
    }

    # In an endpoint you just RETURN it; dispatch sends it for you:
    async sub get ($self, $ctx) {
        return $ctx->json({ message => 'Hello' }, status => 200);
    }

    # Class-method factories build a detached response in one call;
    # status/content_type/headers go as trailing options:
    my $res = PAGI::Response->text("Hello World");
    my $res = PAGI::Response->html("<h1>Hello</h1>");
    my $res = PAGI::Response->json({ data => 'value' });
    my $res = PAGI::Response->json({ error => 'not found' }, status => 404);
    my $res = PAGI::Response->redirect('/login');

    # Because it's a value, it works anywhere an app does:
    $router->mount('/health' => PAGI::Response->json({ ok => \1 }));

    # Streaming: the callback runs at send time (auto-closes when done)
    await PAGI::Response->new($scope)
        ->content_type('text/csv')
        ->stream(async sub ($writer) {
            await $writer->write("id,name\n");
            await $writer->write("1,Alice\n");
        })
        ->respond($send);

    # File downloads:
    await PAGI::Response->new($scope)
        ->send_file('/path/to/file.pdf', filename => 'doc.pdf')
        ->respond($send);

=head1 DESCRIPTION

PAGI::Response provides a fluent interface for building HTTP responses in
PAGI applications. It is a detached value object: it holds status, headers,
and body but has no connection. Sending is done via L</respond> or L</to_app>.

B<Chainable methods> (C<status>, C<header>, C<content_type>, C<cookie>)
return C<$self> for fluent chaining.

B<Body methods> (C<text>, C<html>, C<json>, C<redirect>, etc.) set the
response body and also return C<$self>. They can be called as class-method
factories (C<< PAGI::Response->json($data) >>) or as instance methods
(C<< $res->json($data) >>).

=head1 CONSTRUCTOR

=head2 new

    my $res = PAGI::Response->new;
    my $res = PAGI::Response->new($scope);

Creates a detached response value. The response holds no connection and no
C<$send> callback — it is a pure value object that accumulates status,
headers, and body via the chainer methods.

=over 4

=item C<$scope> - Optional. A PAGI scope hashref. When provided it is stored
inert (for accessors like C<scope()> and helpers like L<PAGI::Stash>).
It is B<not> used as a connection — no C<$send> is stored here.

=back

To actually send the response, call L</respond> with the C<$send> callback,
or mount it as a PAGI app via L</to_app>.

Because the constructor stores no connection, the same response value can be
served to multiple connections (re-entrantly) by calling C<respond> more than
once.

=head1 CHAINABLE METHODS

These methods return C<$self> for fluent chaining.

=head2 status

    $res->status(404);
    my $code = $res->status;

Set or get the HTTP status code (100-599). Returns C<$self> when setting
for fluent chaining. When getting, returns 200 if no status has been set.

    my $res = PAGI::Response->new($scope);
    $res->status;           # 200 (default, nothing set yet)
    $res->has_status;       # false
    $res->status(201);      # set explicitly
    $res->has_status;       # true

=head2 status_try

    $res->status_try(404);

Set the HTTP status code only if one hasn't been set yet. Useful in
middleware or error handlers to provide fallback status codes without
overriding choices made by the application:

    $res->status_try(202);  # sets to 202 (nothing was set)
    $res->status_try(500);  # no-op, 202 already set

=head2 header

    $res->header('X-Custom' => 'value');
    my $value = $res->header('X-Custom');

Add a response header. Can be called multiple times to add multiple headers.
If called with only a name, returns the last value for that header or C<undef>.

=head2 headers

    my $headers = $res->headers;

Returns the response headers as a L<PAGI::Headers> object. The object's C<@{}>
overload yields a copy of the C<[name, value]> pairs in insertion order, so
existing code that iterates C<@{$res->headers}> continues to work.

=head2 header_all

    my @values = $res->header_all('Set-Cookie');

Returns all values for the given header name (case-insensitive).

=head2 header_try

    $res->header_try('X-Custom' => 'value');

Add a response header only if that header name has not already been set.

=head2 remove_header

    $res->remove_header('X-Custom');

Remove all instances of the named header (case-insensitive). Returns C<$self>
for fluent chaining. No-op if the header was not set.

=head2 content_type

    $res->content_type('text/html; charset=utf-8');
    my $type = $res->content_type;
    $res->content_type(undef);   # clears Content-Type so a body method can re-default it

Set the Content-Type header, replacing any existing one. Passing C<undef>
removes Content-Type entirely, which lets a subsequent body method (C<html>,
C<text>, C<json>) re-apply its default.

=head2 content_type_try

    $res->content_type_try('text/html; charset=utf-8');

Set the Content-Type header only if it has not already been set.

=head2 cookie

    $res->cookie('session' => 'abc123',
        max_age  => 3600,
        path     => '/',
        domain   => 'example.com',
        secure   => 1,
        httponly => 1,
        samesite => 'Strict',
    );

Set a response cookie. Options: max_age, expires, path, domain, secure,
httponly, samesite.

=head2 delete_cookie

    $res->delete_cookie('session');

Delete a cookie by setting it with Max-Age=0.

=head2 scope

    my $scope = $res->scope;

Returns the raw PAGI scope hashref. Useful for constructing helper
objects like L<PAGI::Stash> and L<PAGI::Session>:

    my $stash = PAGI::Stash->new($res);

=head2 Per-Request Shared State

See L<PAGI::Stash> for per-request shared state. Construct from a
Response object or from the shared scope:

    use PAGI::Stash;
    my $stash = PAGI::Stash->new($res);

=head2 is_sent

    if ($res->is_sent) {
        warn "Response already sent, cannot send error";
        return;
    }

Returns true if the server-owned C<pagi.connection> object for this request
reports C<response_started> — meaning the response has started on this
connection (headers have been emitted). Reflects a server-owned fact, not a
flag on this Response value.

Returns 0 if there is no C<pagi.connection> in scope (server-less / not
started). Dies (C<croak>) if a C<pagi.connection> is present but lacks the
C<response_started> method, which indicates a non-conforming server.

=head2 has_status

    if ($res->has_status) { ... }

Returns true if a status code has been explicitly set via C<status> or
C<status_try>.

=head2 has_header

    if ($res->has_header('content-type')) { ... }

Returns true if the given header name has been set via C<header> or
C<header_try>. Header names are case-insensitive.

=head2 has_content_type

    if ($res->has_content_type) { ... }

Returns true if Content-Type has been explicitly set via C<content_type>,
C<content_type_try>, or C<header>/C<header_try> with a Content-Type name.

=head2 has_body_source

    if ($res->has_body_source) { ... }

Returns true if a B<body source> has been registered on the response — a
buffered body (via C<text>/C<html>/C<json>/C<send>/C<send_raw>/C<empty>/
C<redirect>), a file (via C<send_file>), or a stream callback (via C<stream>).

This is a B<build-phase, intent-level> signal. It answers "did the handler
register something to send?", B<not> "have any bytes been produced or sent":

=over 4

=item * For a C<stream>, it is true the instant the callback is registered,
B<before> C<respond> runs it and before a single byte is written. A registered
stream that has produced zero bytes still reports C<has_body_source> true — that
is the only coherent meaning, since C<respond> is what drives the stream.

=item * An B<intentional empty body> counts: C<empty>, C<redirect>, and
C<send_raw('')> all register a body (the empty string), so they report true.
A response that has had no body method called reports false.

=item * It is independent of L</is_sent>. C<has_body_source> describes the
value; C<is_sent> describes whether the value has gone out on a connection. For
"has the response been emitted", use C<is_sent>; for "has the stream finished",
C<await> the Future returned by C<respond>.

=back

A response whose handler set only a status or a header (no body method) reports
C<has_body_source> false even though it is a legitimate response (e.g. a bare
C<204> or a redirect built only via C<status> + C<header>). Frameworks deciding
whether to auto-send should therefore test C<< $res->has_body_source ||
$res->has_status >>. See the L<PAGI::Cookbook/RESPONSE STATE & LIFECYCLE>
section for the full state model.

=head2 cors

    # Allow all origins (simplest case)
    $res->cors->json({ data => 'value' });

    # Allow specific origin
    $res->cors(origin => 'https://example.com')->json($data);

    # Full configuration
    $res->cors(
        origin      => 'https://example.com',
        methods     => [qw(GET POST PUT DELETE)],
        headers     => [qw(Content-Type Authorization)],
        expose      => [qw(X-Request-Id X-RateLimit-Remaining)],
        credentials => 1,
        max_age     => 86400,
        preflight   => 0,
    )->json($data);

Add CORS (Cross-Origin Resource Sharing) headers to the response.
Returns C<$self> for chaining.

B<Options:>

=over 4

=item * C<origin> - Allowed origin. Default: C<'*'> (all origins).
Can be a specific origin like C<'https://example.com'> or C<'*'> for any.

=item * C<methods> - Arrayref of allowed HTTP methods for preflight.
Default: C<[qw(GET POST PUT DELETE PATCH OPTIONS)]>.

=item * C<headers> - Arrayref of allowed request headers for preflight.
Default: C<[qw(Content-Type Authorization X-Requested-With)]>.

=item * C<expose> - Arrayref of response headers to expose to the client.
By default, only simple headers (Cache-Control, Content-Language, etc.)
are accessible. Use this to expose custom headers.

=item * C<credentials> - Boolean. If true, sets
C<Access-Control-Allow-Credentials: true>, allowing cookies and
Authorization headers. Default: C<0>.

=item * C<max_age> - How long (in seconds) browsers should cache preflight
results. Default: C<86400> (24 hours).

=item * C<preflight> - Boolean. If true, includes preflight response headers
(Allow-Methods, Allow-Headers, Max-Age). Set this when handling OPTIONS
requests. Default: C<0>.

=item * C<request_origin> - The Origin header value from the request.
Required when C<credentials> is true and C<origin> is C<'*'>, because
the CORS spec forbids using C<'*'> with credentials. Pass the actual
request origin to echo it back.

=back

B<Important CORS Notes:>

=over 4

=item * When C<credentials> is true, you cannot use C<< origin => '*' >>.
Either specify an exact origin, or pass C<request_origin> with the
client's actual Origin header.

=item * The C<Vary: Origin> header is always set to ensure proper caching
when origin-specific responses are used.

=item * For preflight (OPTIONS) requests, set C<< preflight => 1 >> and
typically respond with C<< $res->status(204)->empty() >>.

=back

=head1 SEND PRIMITIVE AND APP MOUNTING

=head2 respond

    await $res->respond($send);

The single send primitive for a detached response value. Reads the
accumulated status, headers, and body from C<$self> and emits the
appropriate PAGI protocol events via C<$send>.

C<$send> must be a coderef (the PAGI send callback). C<respond> does
B<not> mutate the response object, so the same response value can be
passed to C<respond> multiple times for different connections.

For streaming responses (set up via the C<_stream> slot), C<respond>
sends the start event, runs the stream callback with a
L<PAGI::Response::Writer>, and ensures the writer is closed.

Returns a L<Future>.

=head2 to_app

    my $app = $res->to_app;

Returns a PAGI application coderef C<sub ($scope, $receive, $send)> that
calls L</respond> with the given C<$send> when invoked. Use this to mount
a response value directly as a PAGI app:

    my $not_found = PAGI::Response->new
        ->status(404)
        ->_set_body('Not Found', 'text/plain');

    # Mount as a fallback app
    my $app = $not_found->to_app;

=head1 BODY METHODS

These methods set the response body and return C<$self>. Sending happens via
L</respond> / L</to_app> or the endpoint return contract.

Each method works as both a B<class-method factory> and an B<instance method>:

    # Class-method factory — creates a new detached response and returns it
    return $ctx->json($data);                     # instance method on existing $res
    return PAGI::Response->json($data);          # factory shorthand

    # Chain body with other setters before sending
    PAGI::Response->json($data)->status(201)->respond($send)->get;

The Content-Type these methods set is a B<default>: an explicit C<content_type>
set beforehand is preserved, not overridden.

These helpers UTF-8-encode the body, so they make the Content-Type advertise
that encoding. When you preset a charset-less type they append C<; charset=utf-8>
to it — C<< content_type('application/xml')->html($xml) >> sends
C<application/xml; charset=utf-8> (charset is meaningful for XML and C<text/*>,
RFC 7303). The exceptions are C<application/json> and the C<+json> structured-suffix
types, which are left bare: JSON is always UTF-8 and defines no charset parameter
(RFC 8259). An explicit charset you set yourself is never overridden. If you need
a body in some other encoding, encode it yourself and use L</send_raw>.

=head2 Trailing options (status, content_type, headers)

The body methods C<text>, C<html>, C<json>, C<send_raw>, and C<empty> accept
trailing named options as a convenience so you can set status, content-type,
and extra headers in a single call without chaining:

    PAGI::Response->json($data, status => 404);
    PAGI::Response->text('Hi', status => 201, headers => ['X-Foo' => 'bar']);
    PAGI::Response->send_raw($bytes, content_type => 'application/octet-stream');
    PAGI::Response->empty(status => 304);

Recognised options:

=over 4

=item B<status> — HTTP status code (integer).

=item B<content_type> — sets the Content-Type header, overriding any default.

=item B<headers> — a flat arrayref of C<< name => value >> pairs to append.
Example: C<< headers => ['X-Foo' => 'bar', 'X-Baz' => 'qux'] >>.

=back

An unrecognised option name causes an immediate C<croak>, catching typos such
as C<status_code => 404> before they silently send 200.

The existing chaining form C<< ->json($data)->status(404) >> keeps working.

=head2 text

    $res->text("Hello World");
    PAGI::Response->text("Hello World");
    PAGI::Response->text("Not found", status => 404);

Set body to the UTF-8–encoded string with Content-Type: text/plain; charset=utf-8.
Accepts trailing options (C<status>, C<content_type>, C<headers>). Returns C<$self>.

=head2 html

    $res->html("<h1>Hello</h1>");
    PAGI::Response->html("<h1>Hello</h1>");
    PAGI::Response->html("<p>Error</p>", status => 500);

Set body to the UTF-8–encoded string with Content-Type: text/html; charset=utf-8.
Accepts trailing options (C<status>, C<content_type>, C<headers>). Returns C<$self>.

=head2 json

    $res->json({ message => 'Hello' });
    PAGI::Response->json({ message => 'Hello' });
    PAGI::Response->json({ error => 'nope' }, status => 404);

Set body to the JSON-encoded data with Content-Type: application/json. No charset
parameter is added — JSON is always UTF-8 and C<application/json> defines none
(RFC 8259). Accepts trailing options (C<status>, C<content_type>, C<headers>).
Returns C<$self>.

=head2 redirect

    $res->redirect('/login');
    $res->redirect('/new-url', 301);
    PAGI::Response->redirect('/login');

Set an empty body and a Location header. Default status is 302. Returns C<$self>.

B<Why no body?> While RFC 7231 suggests including a short HTML body with a
hyperlink for clients that don't auto-follow redirects, all modern browsers
and HTTP clients ignore redirect bodies. If you need a body for legacy
compatibility, set it explicitly after calling C<redirect>.

=head2 empty

    $res->empty;
    PAGI::Response->new->empty;
    PAGI::Response->empty(status => 304);

Set an empty body with status 204 No Content (or keep a previously set status).
Accepts trailing options (C<status>, C<content_type>, C<headers>); an explicit
C<status> option overrides the 204 default. Returns C<$self>.

=head2 send

    $res->send($text);
    $res->send($text, charset => 'iso-8859-1');

Set body to the encoded text (UTF-8 by default, or the specified charset).
Defaults the Content-Type to C<text/plain> and appends the charset to a
charset-less type, on the same rules as L</text> (C<application/json> and
C<+json> types stay bare). Returns C<$self>.

=head2 send_raw

    $res->send_raw($bytes);
    PAGI::Response->send_raw($bytes, content_type => 'application/octet-stream');

Set body to raw bytes without any encoding. Use for binary data or pre-encoded
content. Accepts trailing options (C<status>, C<content_type>, C<headers>).
Returns C<$self>.

=head2 stream

    $res->stream(async sub {
        my ($writer) = @_;
        await $writer->write("chunk1");
        await $writer->write("chunk2");
        await $writer->close();
    });
    PAGI::Response->stream($callback);

Store a streaming callback. When the response is sent via L</respond>, the callback
receives a L<PAGI::Response::Writer> and streams chunks. Returns C<$self>.

=head2 writer

    my $writer = await $res->writer($send);
    my $writer = await $res->writer($send, on_close => sub { cleanup() });
    my $writer = await $res->writer($send, on_close => async sub { await cleanup() });

Returns a L<PAGI::Response::Writer> directly, sending headers immediately.
Unlike C<stream()>, the writer is not scoped to a callback — you own it
and must call C<close()> when done.

C<$send> must be a coderef (the PAGI send callback). This is the same
C<$send> you would pass to L</respond>.

This is useful when the writer needs to be passed to event handlers,
pub/sub callbacks, timers, or other contexts outside a single function:

    async sub live_feed {
        my ($self, $ctx) = @_;
        my $writer = await $ctx->response
            ->content_type('text/plain')
            ->writer($ctx->send, on_close => sub { $bus->unsubscribe($id) });

        my $id = $bus->subscribe(async sub ($line) {
            await $writer->write("$line\n");
        });

        await $ctx->receive;    # wait for disconnect
        await $writer->close;
    }

The optional C<on_close> callback is registered before headers are sent,
eliminating any race window with fast client disconnects. Sync and async
callbacks are both supported — see L</on_close> under L</WRITER OBJECT>.

=head2 send_file

    $res->send_file('/path/to/file.pdf');
    $res->send_file('/path/to/file.pdf',
        filename => 'download.pdf',
        inline   => 1,
    );
    PAGI::Response->send_file('/path/to/file.pdf');

    # Partial file (for range requests)
    $res->send_file('/path/to/video.mp4',
        offset => 1024,       # Start from byte 1024
        length => 65536,      # Send 64KB
    );

Set the response to serve a file. Stats the file and sets Content-Type,
Content-Length, and Content-Disposition at call time. The PAGI protocol's
C<file> key is used for efficient server-side streaming (file not read into
memory) when L</respond> is called. Returns C<$self>.

For production, use L<PAGI::Middleware::XSendfile> to delegate file serving
to your reverse proxy.

B<Options:>

=over 4

=item * C<filename> - Set Content-Disposition attachment filename

=item * C<inline> - Use Content-Disposition: inline instead of attachment

=item * C<offset> - Start position in bytes (default: 0). For range requests.

=item * C<length> - Number of bytes to send. Defaults to file size minus offset.

=back

B<Range Request Example:>

    # Manual range request handling
    async sub handle_video {
        my ($req, $send) = @_;
        my $path = '/videos/movie.mp4';
        my $size = -s $path;

        my $range = $req->header('Range');
        if ($range && $range =~ /bytes=(\d+)-(\d*)/) {
            my $start = $1;
            my $end = $2 || ($size - 1);
            my $length = $end - $start + 1;

            return await PAGI::Response->new
                ->status(206)
                ->header('Content-Range' => "bytes $start-$end/$size")
                ->header('Accept-Ranges' => 'bytes')
                ->send_file($path, offset => $start, length => $length)
                ->respond($send);
        }

        return await PAGI::Response->new
            ->header('Accept-Ranges' => 'bytes')
            ->send_file($path)
            ->respond($send);
    }

B<Note:> For production file serving with full features (ETag caching,
automatic range request handling, conditional GETs, directory indexes),
use L<PAGI::App::File> instead:

    use PAGI::App::File;
    my $files = PAGI::App::File->new(root => '/var/www/static');
    my $app = $files->to_app;

=head1 EXAMPLES

=head2 Complete Raw PAGI Application

    use Future::AsyncAwait;
    use PAGI::Request;
    use PAGI::Response;

    my $app = async sub ($scope, $receive, $send) {
        return await handle_lifespan($scope, $receive, $send)
            if $scope->{type} eq 'lifespan';

        my $req = PAGI::Request->new($scope, $receive);
        my $res = $req->response;

        if ($req->method eq 'GET' && $req->path eq '/') {
            return await $res->html('<h1>Welcome</h1>')->respond($send);
        }

        if ($req->method eq 'POST' && $req->path eq '/api/users') {
            my $data = await $req->json;
            # ... create user ...
            return await $res->status(201)
                             ->header('Location' => '/api/users/123')
                             ->json({ id => 123, name => $data->{name} })
                             ->respond($send);
        }

        return await $res->status(404)->json({ error => 'Not Found' })->respond($send);
    };

=head2 Form Validation with Error Response

    async sub handle_contact ($req, $send) {
        my $res = $req->response;
        my $form = await $req->form_params;

        my @errors;
        my $email = $form->get('email') // '';
        my $message = $form->get('message') // '';

        push @errors, 'Email required' unless $email;
        push @errors, 'Invalid email' unless $email =~ /@/;
        push @errors, 'Message required' unless $message;

        if (@errors) {
            return await $res->status(422)
                             ->json({ error => 'Validation failed', errors => \@errors })
                             ->respond($send);
        }

        # Process valid form...
        return await $res->json({ success => 1 })->respond($send);
    }

=head2 Authentication with Cookies

    async sub handle_login ($req, $send) {
        my $res = $req->response;
        my $data = await $req->json;

        my $user = authenticate($data->{email}, $data->{password});

        unless ($user) {
            return await $res->status(401)->json({ error => 'Invalid credentials' })->respond($send);
        }

        my $session_id = create_session($user);

        return await $res->cookie('session' => $session_id,
                path     => '/',
                httponly => 1,
                secure   => 1,
                samesite => 'Strict',
                max_age  => 86400,  # 24 hours
            )
            ->json({ user => { id => $user->{id}, name => $user->{name} } })
            ->respond($send);
    }

    async sub handle_logout ($req, $send) {
        my $res = $req->response;

        return await $res->delete_cookie('session', path => '/')
                         ->json({ logged_out => 1 })
                         ->respond($send);
    }

=head2 File Download

    async sub handle_download ($req, $send) {
        my $res = $req->response;
        my $file_id = $req->path_param('id');

        my $file = get_file($file_id); # Be sure to clean $file
        unless ($file && -f $file->{path}) {
            return await $res->status(404)->json({ error => 'File not found' })->respond($send);
        }

        return await $res->send_file($file->{path},
            filename => $file->{original_name},
        )->respond($send);
    }

=head2 Streaming Large Data

    async sub handle_export ($req, $send) {
        my $res = $req->response;

        await $res->content_type('text/csv')
                  ->header('Content-Disposition' => 'attachment; filename="export.csv"')
                  ->stream(async sub ($writer) {
                      # Write CSV header
                      await $writer->write("id,name,email\n");

                      # Stream rows from database
                      my $cursor = get_all_users_cursor();
                      while (my $user = $cursor->next) {
                          await $writer->write("$user->{id},$user->{name},$user->{email}\n");
                      }
                  })
                  ->respond($send);
    }

=head2 Server-Sent Events Style Streaming

    async sub handle_events ($req, $send) {
        my $res = $req->response;

        await $res->content_type('text/event-stream')
                  ->header('Cache-Control' => 'no-cache')
                  ->stream(async sub ($writer) {
                      for my $i (1..10) {
                          await $writer->write("data: Event $i\n\n");
                          await some_delay(1);  # Wait 1 second
                      }
                  })
                  ->respond($send);
    }

=head2 Conditional Responses

    async sub handle_resource ($req, $send) {
        my $res = $req->response;
        my $etag = '"abc123"';

        # Check If-None-Match for caching
        my $if_none_match = $req->header('If-None-Match') // '';
        if ($if_none_match eq $etag) {
            return await $res->status(304)->empty()->respond($send);
        }

        return await $res->header('ETag' => $etag)
                         ->header('Cache-Control' => 'max-age=3600')
                         ->json({ data => 'expensive computation result' })
                         ->respond($send);
    }

=head2 CORS API Endpoint

    # Simple CORS - allow all origins
    async sub handle_api ($scope, $receive, $send) {
        my $res = PAGI::Response->new($scope);

        return await $res->cors->json({ status => 'ok' })->respond($send);
    }

    # CORS with credentials (e.g., cookies, auth headers)
    async sub handle_api_with_auth ($scope, $receive, $send) {
        my $req = PAGI::Request->new($scope, $receive);
        my $res = $req->response;

        # Get the Origin header from request
        my $origin = $req->header('Origin');

        return await $res->cors(
            origin         => 'https://myapp.com',  # Or use request_origin
            credentials    => 1,
            expose         => [qw(X-Request-Id)],
        )->json({ user => 'authenticated' })->respond($send);
    }

=head2 CORS Preflight Handler

    # Handle OPTIONS preflight requests
    async sub app ($scope, $receive, $send) {
        my $req = PAGI::Request->new($scope, $receive);
        my $res = $req->response;

        # Handle preflight
        if ($req->method eq 'OPTIONS') {
            return await $res->cors(
                origin      => 'https://myapp.com',
                methods     => [qw(GET POST PUT DELETE)],
                headers     => [qw(Content-Type Authorization X-Custom-Header)],
                credentials => 1,
                max_age     => 86400,
                preflight   => 1,  # Include preflight headers
            )->status(204)->empty()->respond($send);
        }

        # Handle actual request
        return await $res->cors(
            origin      => 'https://myapp.com',
            credentials => 1,
        )->json({ data => 'response' })->respond($send);
    }

=head2 Dynamic CORS Origin

    # Allow multiple origins dynamically
    my %ALLOWED_ORIGINS = map { $_ => 1 } qw(
        https://app1.example.com
        https://app2.example.com
        https://localhost:3000
    );

    async sub handle_api ($scope, $receive, $send) {
        my $req = PAGI::Request->new($scope, $receive);
        my $res = $req->response;

        my $request_origin = $req->header('Origin') // '';

        # Check if origin is allowed
        if ($ALLOWED_ORIGINS{$request_origin}) {
            return await $res->cors(
                origin      => $request_origin,  # Echo back the allowed origin
                credentials => 1,
            )->json({ data => 'allowed' })->respond($send);
        }

        # Origin not allowed - respond without CORS headers
        return await $res->status(403)->json({ error => 'Origin not allowed' })->respond($send);
    }

=head1 WRITER OBJECT

The C<stream()> method passes a writer object to its callback, and
C<writer()> returns one directly. The writer has the following methods:

=head3 write

    await $writer->write($chunk);

Write a chunk of data to the response stream. Returns a L<Future>.

Writing after close returns a failed L<Future> rather than throwing.
This allows cleanup code that races with close to handle the error
gracefully via C<await>.

=head3 close

    await $writer->close;

Close the stream. Returns a L<Future>. Calling close multiple times is
safe — subsequent calls are no-ops.

=head3 bytes_written

    my $n = $writer->bytes_written;

Returns the total number of bytes written so far.

=head3 on_close

    # Sync callback
    $writer->on_close(sub { cleanup() });

    # Async callback — return value is awaited automatically
    $writer->on_close(async sub {
        await notify_stream_ended();
    });

    # Chaining
    $writer->on_close(sub { ... })
           ->on_close(sub { ... });

Registers a callback to fire when the writer closes (either explicitly
or via C<stream()> auto-close). Callbacks can be regular subs or async
subs — async results are automatically awaited. Multiple callbacks run
in registration order. Exceptions are caught and warned but do not
prevent other callbacks from running. Returns C<$self> for chaining.

B<Circular reference note:> If your callback captures the writer
object in a closure, use C<Scalar::Util::weaken> to avoid a memory leak:

    use Scalar::Util qw(weaken);
    my $weak_writer = $writer;
    weaken($weak_writer);
    $writer->on_close(sub { $weak_writer->... if $weak_writer });

The callback array is cleared after firing, so any cycle via a closure
is broken when the writer closes, but C<weaken> prevents the object
from being kept alive until that point.

=head3 is_closed

    if ($writer->is_closed) { ... }

Returns true if the writer has been closed.

The writer automatically closes when the C<stream()> callback completes,
but calling C<close()> explicitly is recommended for clarity.

=head1 ERROR AND ALTERNATE RESPONSES

A response is a value, so "produce a 404 instead" is just returning a different
value -- no exceptions needed:

    async sub show ($self, $ctx) {
        my $user = await find_user($ctx->req->path_param('id'));
        return PAGI::Response->json({ error => 'not found' }, status => 404)
            unless $user;
        return $ctx->json($user);
    }

For cases that recur across handlers, prefer modeling the absence as a value
(a "null object") whose own method returns the right response, instead of
throwing from deep in the stack:

    my $user = await find_user($ctx) // UnauthenticatedUser->new($ctx);
    return $user->dashboard;   # a real user renders; an UnauthenticatedUser
                               # returns a 401 / login response

Here C<UnauthenticatedUser> is a class you define; its C<dashboard> method
returns a C<PAGI::Response> just as a real user's would.

=head1 SUBCLASSING (FRAMEWORK INTEGRATION)

Framework authors can subclass C<PAGI::Response> to add their own response
sugar while reusing the value machinery. The contract is small and stable:

=over 4

=item * B<Construct via> C<< $class->new($scope) >>. The scope is optional and
inert (used only for C<scope()> and helpers like L<PAGI::Stash>); a response
never holds a connection. A Moose subclass can C<extends 'PAGI::Response'> and
provide C<FOREIGNBUILDARGS> returning C<($scope)>.

=item * B<Override> C<< respond($send) >> to customize how the response is sent.
Call C<< $self->SUPER::respond($send) >> to do the actual emission. The
connection (C<$send>) arrives as the argument; do not store or re-bind it -- a
response value is connection-free until the moment it is sent.

=item * B<Build on the public surface> -- C<status>, C<header>, C<headers>,
C<content_type>, C<cookie>, C<cors>, C<is_sent>, the C<has_*> predicates
(C<has_status>, C<has_header>, C<has_content_type>, C<has_body_source>), and
the body methods (C<text>/C<html>/C<json>/C<send_raw>/C<empty>/C<redirect>/
C<stream>/C<send_file>, with trailing options). Do B<not> reach into the
C<_>-prefixed internals (C<_headers>, C<_body>, C<_status>, C<_stream>, ...);
they are private and may change.

=item * Adding response sugar via a role/mixin works unchanged -- a role that
calls the public chainers and body methods needs no special support.

=back

A response value never needs C<$send> until it is sent, so "I don't have a
connection here" just means "I am not sending yet": hold the value and call
C<respond> (or return it from an endpoint, where dispatch sends it) when a
connection is available.

=head1 SEE ALSO

L<PAGI>, L<PAGI::Request>, L<PAGI::Server>

=head1 AUTHOR

PAGI Contributors

=cut

sub new {
    my ($class, $scope) = @_;
    croak("scope must be a hashref") if defined $scope && ref($scope) ne 'HASH';
    return bless {
        scope    => $scope,           # optional, inert (accessors / Stash); NOT a connection
        _headers => PAGI::Headers->new,
    }, $class;
}

sub status {
    my ($self, $code) = @_;
    return $self->{_status} // 200 if @_ == 1;  # lazy default
    croak("Status must be a number between 100-599")
        unless $code =~ /^\d+$/ && $code >= 100 && $code <= 599;
    $self->{_status} = $code;
    return $self;
}

sub status_try {
    my ($self, $code) = @_;
    return $self if exists $self->{_status};
    return $self->status($code);
}

sub header {
    my ($self, $name, $value) = @_;
    croak("Header name is required") unless defined $name;
    return $self->{_headers}->get($name) if @_ == 2;   # getter: last value
    $self->{_headers}->add($name, $value);              # setter: append
    return $self;
}

sub headers { return $_[0]->{_headers} }

sub header_all {
    my ($self, $name) = @_;
    croak("Header name is required") unless defined $name;
    return $self->{_headers}->get_all($name);
}

sub header_try {
    my ($self, $name, $value) = @_;
    $self->{_headers}->set_default($name, $value);
    return $self;
}

sub remove_header {
    my ($self, $name) = @_;
    croak("Header name is required") unless defined $name;
    $self->{_headers}->remove($name);
    return $self;
}

sub content_type {
    my ($self, $type) = @_;
    return $self->{_headers}->get('content-type') if @_ == 1;   # getter
    if (defined $type) { $self->{_headers}->set('content-type', $type) }
    else               { $self->{_headers}->remove('content-type') }  # content_type(undef) clears
    return $self;
}

sub content_type_try {
    my ($self, $type) = @_;
    $self->{_headers}->set_default('content-type', $type);
    return $self;
}

sub has_status {
    my ($self) = @_;
    return exists $self->{_status} ? 1 : 0;
}

sub has_header       { return $_[0]->{_headers}->has($_[1]) }
sub has_content_type { return $_[0]->{_headers}->has('content-type') }

sub has_body_source {
    my ($self) = @_;
    return (exists $self->{_body} || exists $self->{_stream} || exists $self->{_file}) ? 1 : 0;
}

sub scope { shift->{scope} }

sub _set_body {
    my ($self, $bytes, $default_type) = @_;
    $self->{_body} = $bytes;
    $self->content_type_try($default_type) if defined $default_type;
    return $self;
}

# The UTF-8 text body helpers call this so the Content-Type advertises the
# encoding they just applied. A charset is appended only when the type both
# lacks one and actually defines a charset parameter. application/json and the
# structured-suffix +json types define none — JSON is always UTF-8 per RFC 8259
# — so they are left bare; application/xml, text/*, and the +xml types do carry
# charset (RFC 7303), so they get it.
sub _ensure_charset {
    my ($self, $charset) = @_;
    $charset //= 'utf-8';
    return $self unless $self->has_content_type;
    my $ct = $self->content_type;
    return $self if $ct =~ /charset=/i;
    my ($type) = $ct =~ m{^\s*([^;]+)};
    $type //= '';
    $type =~ s/\s+\z//;
    return $self if lc($type) eq 'application/json' || $type =~ /\+json\z/i;
    $self->content_type("$ct; charset=$charset");
    return $self;
}

sub _render_headers {
    my ($self, $extra_len) = @_;
    my $pairs = $self->{_headers}->to_pairs;
    if (defined $extra_len) {
        # Buffered response: Content-Length is authoritative. Drop any user-set
        # Content-Length (no duplicates) and any Transfer-Encoding (CL+TE is a
        # request-smuggling vector), then append the one true length.
        @$pairs = grep {
            (my $k = $_->[0]) =~ tr/A-Z/a-z/;   # ASCII fold (field names are ASCII tokens)
            $k ne 'content-length' && $k ne 'transfer-encoding'
        } @$pairs;
        push @$pairs, ['content-length', $extra_len];
    }
    return $pairs;
}

async sub respond {
    my ($self, $send) = @_;
    croak("send must be a coderef") unless ref($send) eq 'CODE';

    if ($self->{_stream}) {
        await $send->({
            type    => 'http.response.start',
            status  => $self->status,
            headers => $self->_render_headers(undef),
        });
        my $writer = PAGI::Response::Writer->new($send);
        await $self->{_stream}->($writer);
        await $writer->close() unless $writer->is_closed;
        return;
    }

    if ($self->{_file}) {
        my $fd = $self->{_file};
        # Headers (incl. content-length) were set at send_file() build time.
        await $send->({
            type    => 'http.response.start',
            status  => $self->status,
            headers => $self->_render_headers(undef),
        });
        my $body_event = {
            type => 'http.response.body',
            file => $fd->{path},
        };
        $body_event->{offset} = $fd->{offset} if exists $fd->{offset};
        $body_event->{length} = $fd->{length} if exists $fd->{length};
        await $send->($body_event);
        return;
    }

    my $body = $self->{_body} // '';
    await $send->({
        type    => 'http.response.start',
        status  => $self->status,
        headers => $self->_render_headers(length $body),
    });
    await $send->({ type => 'http.response.body', body => $body, more => 0 });
    return;
}

sub to_app {
    my ($self) = @_;
    return async sub {
        my ($scope, $receive, $send) = @_;
        await $self->respond($send);
    };
}


sub is_sent {
    my ($self) = @_;
    my $conn = $self->{scope} ? $self->{scope}{'pagi.connection'} : undef;
    return 0 unless $conn;                       # no connection object: server-less / not started
    Carp::croak("pagi.connection lacks response_started (non-conforming server)")
        unless $conn->can('response_started');
    return $conn->response_started ? 1 : 0;
}

# Returns the invocant if it is already an instance; otherwise creates a new
# detached instance from the class name. Allows finisher methods to be called
# as either class-method factories or instance methods.
sub _self_or_new {
    my ($proto) = @_;
    return ref($proto) ? $proto : $proto->new;
}

# Encode a text string to UTF-8 bytes, croaking on invalid characters.
# Replicates the encoding used by the old send() method.
sub _enc {
    my ($str, $charset) = @_;
    $charset //= 'utf-8';
    return encode($charset, $str // '', FB_CROAK);
}

my %_RESPONSE_OPTS = map { $_ => 1 } qw(status content_type headers);

sub _apply_opts {
    my ($self, %opts) = @_;
    for my $k (keys %opts) {
        croak "Unknown response option '$k' (known: status, content_type, headers)"
            unless $_RESPONSE_OPTS{$k};
    }
    $self->status($opts{status}) if defined $opts{status};
    $self->content_type($opts{content_type}) if defined $opts{content_type};
    if (my $h = $opts{headers}) {
        croak "headers must be an even-length arrayref [ name => value, ... ]"
            if @$h % 2;
        my @pairs = @$h;
        while (@pairs) {
            my ($name, $value) = splice(@pairs, 0, 2);
            $self->header($name, $value);
        }
    }
    return $self;
}

sub send_raw {
    my ($proto, $body, %opts) = @_;
    my $self = $proto->_self_or_new;
    $self->_set_body($body // '', undef);
    $self->_apply_opts(%opts);
    return $self;
}

sub send {
    my ($proto, $body, %opts) = @_;
    my $self   = $proto->_self_or_new;
    my $charset = $opts{charset} // 'utf-8';
    my $encoded = _enc($body, $charset);
    $self->content_type("text/plain; charset=$charset") unless $self->has_content_type;
    $self->_ensure_charset($charset);
    $self->{_body} = $encoded;
    return $self;
}

sub text {
    my ($proto, $body, %opts) = @_;
    my $self = $proto->_self_or_new;
    $self->_set_body(_enc($body), 'text/plain; charset=utf-8');
    $self->_apply_opts(%opts);
    $self->_ensure_charset;
    return $self;
}

sub html {
    my ($proto, $body, %opts) = @_;
    my $self = $proto->_self_or_new;
    $self->_set_body(_enc($body), 'text/html; charset=utf-8');
    $self->_apply_opts(%opts);
    $self->_ensure_charset;
    return $self;
}

sub json {
    my ($proto, $data, %opts) = @_;
    my $self = $proto->_self_or_new;
    my $body = JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode($data);
    $self->_set_body($body, 'application/json');
    $self->_apply_opts(%opts);
    $self->_ensure_charset;
    return $self;
}

sub redirect {
    my ($proto, $url, $status) = @_;
    my $self = $proto->_self_or_new;
    $self->status($status // 302)->header('location', $url);
    $self->_set_body('', undef);
    return $self;
}

sub empty {
    my ($proto, %opts) = @_;
    my $self = $proto->_self_or_new;
    $self->status_try(204);
    $self->_set_body('', undef);
    $self->_apply_opts(%opts);
    return $self;
}

sub cookie {
    my ($self, $name, $value, %opts) = @_;
    my @parts = ("$name=$value");

    push @parts, "Max-Age=$opts{max_age}" if defined $opts{max_age};
    push @parts, "Expires=$opts{expires}" if defined $opts{expires};
    push @parts, "Path=$opts{path}" if defined $opts{path};
    push @parts, "Domain=$opts{domain}" if defined $opts{domain};
    push @parts, "Secure" if $opts{secure};
    push @parts, "HttpOnly" if $opts{httponly};
    push @parts, "SameSite=$opts{samesite}" if defined $opts{samesite};

    my $cookie_str = join('; ', @parts);
    $self->{_headers}->add('set-cookie', $cookie_str);

    return $self;
}

sub delete_cookie {
    my ($self, $name, %opts) = @_;
    return $self->cookie($name, '',
        max_age => 0,
        path    => $opts{path},
        domain  => $opts{domain},
    );
}

sub cors {
    my ($self, %opts) = @_;
    my $origin      = $opts{origin} // '*';
    my $credentials = $opts{credentials} // 0;
    my $methods     = $opts{methods} // [qw(GET POST PUT DELETE PATCH OPTIONS)];
    my $headers     = $opts{headers} // [qw(Content-Type Authorization X-Requested-With)];
    my $expose      = $opts{expose} // [];
    my $max_age     = $opts{max_age} // 86400;
    my $preflight   = $opts{preflight} // 0;

    # Determine the origin to send back
    my $allow_origin;
    if ($origin eq '*' && $credentials) {
        # With credentials, can't use wildcard - use request_origin if provided
        $allow_origin = $opts{request_origin} // '*';
    } else {
        $allow_origin = $origin;
    }

    # Core CORS headers (always set)
    $self->header('Access-Control-Allow-Origin', $allow_origin);
    $self->header('Vary', 'Origin');

    if ($credentials) {
        $self->header('Access-Control-Allow-Credentials', 'true');
    }

    if (@$expose) {
        $self->header('Access-Control-Expose-Headers', join(', ', @$expose));
    }

    # Preflight headers (for OPTIONS responses or when explicitly requested)
    if ($preflight) {
        $self->header('Access-Control-Allow-Methods', join(', ', @$methods));
        $self->header('Access-Control-Allow-Headers', join(', ', @$headers));
        $self->header('Access-Control-Max-Age', $max_age);
    }

    return $self;
}

sub stream {
    my ($proto, $callback) = @_;
    my $self = $proto->_self_or_new;
    $self->{_stream} = $callback;
    return $self;
}

async sub writer {
    my ($self, $send, %opts) = @_;
    croak("send must be a coderef") unless ref($send) eq 'CODE';
    # A writer takes over the connection for live streaming; it can only be
    # taken once on a given response value. (The cross-stack "did a response
    # start" fact lives on pagi.connection; this is a local single-takeover guard.)
    croak("Response already sent") if $self->{_writer_started};
    $self->{_writer_started} = 1;

    # Send headers
    await $send->({
        type    => 'http.response.start',
        status  => $self->status,
        headers => $self->_render_headers(undef),
    });

    return PAGI::Response::Writer->new($send, %opts);
}

# Simple MIME type mapping
my %MIME_TYPES = (
    '.html' => 'text/html',
    '.htm'  => 'text/html',
    '.txt'  => 'text/plain',
    '.css'  => 'text/css',
    '.js'   => 'application/javascript',
    '.json' => 'application/json',
    '.xml'  => 'application/xml',
    '.pdf'  => 'application/pdf',
    '.zip'  => 'application/zip',
    '.png'  => 'image/png',
    '.jpg'  => 'image/jpeg',
    '.jpeg' => 'image/jpeg',
    '.gif'  => 'image/gif',
    '.svg'  => 'image/svg+xml',
    '.ico'  => 'image/x-icon',
    '.woff' => 'font/woff',
    '.woff2'=> 'font/woff2',
);

sub _mime_type {
    my ($path) = @_;
    my ($ext) = $path =~ /(\.[^.]+)$/;
    return $MIME_TYPES{lc($ext // '')} // 'application/octet-stream';
}

sub send_file {
    my ($proto, $path, %opts) = @_;
    my $self = $proto->_self_or_new;

    croak("File not found: $path") unless -f $path;
    croak("Cannot read file: $path") unless -r $path;

    # Get file size
    my $file_size = -s $path;

    # Handle offset and length for range requests
    my $offset = $opts{offset} // 0;
    my $length = $opts{length};

    # Validate offset
    croak("offset must be non-negative") if $offset < 0;
    croak("offset exceeds file size") if $offset > $file_size;

    # Calculate actual length to send
    my $max_length = $file_size - $offset;
    if (defined $length) {
        croak("length must be non-negative") if $length < 0;
        $length = $max_length if $length > $max_length;
    } else {
        $length = $max_length;
    }

    # Set content-type if not already set
    $self->content_type_try(_mime_type($path));

    # Set content-length based on actual bytes to send
    $self->header('content-length', $length);

    # Set content-disposition
    my $disposition;
    if ($opts{inline}) {
        $disposition = 'inline';
    } elsif ($opts{filename}) {
        # Sanitize filename for header
        my $safe_filename = $opts{filename};
        $safe_filename =~ s/["\r\n]//g;
        $disposition = "attachment; filename=\"$safe_filename\"";
    }
    $self->header('content-disposition', $disposition) if $disposition;

    # Store the file send descriptor; respond() handles the actual emission.
    # offset/length are stored only when they narrow the full-file default.
    my $file_desc = { path => $path };
    $file_desc->{offset} = $offset if $offset > 0;
    $file_desc->{length} = $length if $length < $max_length;
    $self->{_file} = $file_desc;

    return $self;
}

# Writer class for streaming responses
package PAGI::Response::Writer {
    use strict;
    use warnings;
    use Future::AsyncAwait;
    use Carp qw(croak);
    use Scalar::Util qw(blessed);

    sub new {
        my ($class, $send, %opts) = @_;
        my $self = bless {
            send          => $send,
            bytes_written => 0,
            closed        => 0,
            _on_close     => [],
        }, $class;
        push @{$self->{_on_close}}, $opts{on_close} if $opts{on_close};
        return $self;
    }

    async sub write {
        my ($self, $chunk) = @_;
        die 'Writer already closed' if $self->{closed};
        $self->{bytes_written} += length($chunk // '');
        await $self->{send}->({
            type => 'http.response.body',
            body => $chunk,
            more => 1,
        });
    }

    async sub close {
        my ($self) = @_;
        return if $self->{closed};
        $self->{closed} = 1;
        await $self->{send}->({
            type => 'http.response.body',
            body => '',
            more => 0,
        });
        for my $cb (@{$self->{_on_close}}) {
            eval {
                my $r = $cb->();
                if (blessed($r) && $r->isa('Future')) {
                    await $r;
                }
            };
            if ($@) {
                warn "PAGI::Response::Writer on_close callback error: $@";
            }
        }

        # Clear callback array to break any closure-based cycles
        $self->{_on_close} = [];
    }

    sub on_close {
        my ($self, $cb) = @_;
        push @{$self->{_on_close}}, $cb;
        return $self;
    }

    sub is_closed { $_[0]->{closed} }

    sub bytes_written { $_[0]->{bytes_written} }
}
$PAGI::Response::Writer::VERSION = '0.002001';

1;
