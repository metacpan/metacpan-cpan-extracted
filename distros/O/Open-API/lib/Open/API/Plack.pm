package Open::API::Plack;

use 5.008003;
use strict;
use warnings;
use Open::API;   # loads the shared XS

our $VERSION = '0.10';

1;

__END__

=head1 NAME

Open::API::Plack - the PSGI app for a compiled OpenAPI spec

=head1 SYNOPSIS

    use Open::API::Plack;

    my $plack = Open::API::Plack->new(spec => 'openapi.json');  # or api => $api

    # configuration accumulates - register handlers from anywhere at boot
    $plack->handlers(
        listPets => 'MyApp::Pets::list',    # resolved once, at to_app time
        getPet   => sub {
            my ($params, $env) = @_;
            my $pet = find_pet($params->{path}{petId});   # already typed
            $pet || [ 404, ['Content-Type' => 'text/plain'], ['gone'] ];
        },
    );
    $plack->before(sub { ... });
    $plack->after(sub { ... });   # setters chain

    my $app = $plack->to_app;   # finalise into the PSGI coderef

    # or everything up front, chained straight into to_app:
    my $app = Open::API::Plack->new(
        spec     => 'openapi.json',
        handlers => { listPets => 'MyApp::Pets::list' },
	ui => 1,
    )->to_app;

=head1 DESCRIPTION

The server side of L<Open::API>.

Configuration is two-phase. C<new> and the accessors only accumulate options
- handlers, hooks and security checkers can be registered dynamically, from
multiple modules, in any order. C<to_app> then finalises: handler and hook
names resolve, the spec's security coverage is checked, and the app closure
is built. Anything wrong with the configuration croaks there, at startup.

It runs on any PSGI server. On L<Hyperman> a handler may return a Future and
the worker keeps serving other connections while it resolves.

=head1 CONSTRUCTOR

=head2 new

    my $plack = Open::API::Plack->new(
        api                => $open_api,      # or spec => (see Open::API/new)
        handlers           => { $operationId => sub { ... }, ... },
        before             => sub { ... },   # optional (see HOOKS)
        after              => sub { ... },   # optional (see HOOKS)
        security           => { $scheme => sub { ... }, ... },  # see SECURITY
        csrf               => { ... },        # optional (see CSRF)
        headers            => { ... },        # response headers (see RESPONSE HEADERS)
        cors               => { ... },        # optional (see CORS)
        max_body_size      => 1_048_576,      # bytes; 413 over this
        negotiate          => 0,              # 415 / 406 (see NEGOTIATION)
        error_format       => 'json',         # or 'problem' (RFC 7807)
        validate_responses => 0,
        ui                 => 0,              # docs UI (see UI)
    );

Every option is optional here - each can also be supplied (or extended)
later through the accessor of the same name. C<api> must be an L<Open::API>;
C<spec> is anything L<Open::API/new> accepts and is compiled into C<api>
immediately, so a malformed document croaks at construction. One of the two
must have been given by the time L</to_app> is called. Everything else is
stored as-is and validated by C<to_app>.

=head1 ACCESSORS

Setters return the object, so calls chain. Called with no argument, each
returns the stored value (C<undef> when unset).

=head2 handlers

    $plack->handlers(listPets => sub { ... }, getPet => 'MyApp::get');
    $plack->handlers({ deletePet => sub { ... } });   # a hashref merges too
    my $map = $plack->handlers;                        # the live hashref

Registers operation handlers. Multiple calls B<merge>: each call adds or
overwrites the named operationIds and keeps the rest, so different modules
can register their own handlers independently before the app is finalised.
The getter returns the live map (created empty on first use) - delete from
it to unregister.

=head2 security

    $plack->security(ApiKey => sub { ... });
    my $checkers = $plack->security;

The scheme => checker map (see L</SECURITY>). Same merge semantics as
L</handlers>.

=head2 before

=head2 after

Get/set the request hooks (see L</HOOKS>). Each takes a coderef or a fully
qualified sub name; names resolve at C<to_app> time.

=head2 csrf

=head2 cors

=head2 headers

Get/set the corresponding option hashref (see L</CSRF>, L</CORS> and
L</RESPONSE HEADERS>). Setting replaces the whole hashref.

=head2 max_body_size

=head2 negotiate

=head2 error_format

=head2 validate_responses

Get/set the scalar options (see L</to_app> and the sections below).

=head2 ui

    $plack->ui(1);
    $plack->ui({ path => '/documentation', title => 'My API' });

Get/set the docs UI option (see L</UI>). Setting replaces the value.

=head2 api

Get/set the compiled L<Open::API>. The setter croaks unless given an
Open::API (or subclass) instance.

=head2 spec

    $plack->spec('openapi.yaml');

Compile a spec - anything L<Open::API/new> accepts - into L</api> right
away. The getter returns the compiled Open::API (the same object C<api>
returns).

=head1 THE PSGI APP

=head2 to_app

    my $app = $plack->to_app;

Takes no arguments: finalise the stored configuration and return the PSGI
coderef. Handler, hook and checker names given as strings
(C<'MyApp::listPets'>) are resolved here, so a typo croaks at startup rather
than surfacing per request; every security scheme the spec's operations
require must have a checker (see L</SECURITY>); the csrf, cors and header
options are normalised. The object can be reconfigured and C<to_app> called
again - each call builds an independent app from the configuration at that
moment.

The request path runs in C: route the method and path, validate and
assemble every declared input, then call

    $handlers->{$operationId}->(\%params, $env);

C<%params> has C<path>, C<query>, C<header> and C<cookie> hashes (validated,
percent-decoded, defaults applied; query parameters declared as arrays become
arrayrefs) and C<body> - the JSON-decoded, schema-validated request body (raw
bytes for declared non-JSON content types).

The handler may return:

=over 4

=item * a PSGI triplet - passed through untouched;

=item * any other value - JSON-encoded as a C<200 application/json>;

=item * an object with C<on_ready> (a Future). On a non-blocking server
(C<psgi.nonblocking>, e.g. Hyperman) it is handed to the server to await -
the worker serves other connections meanwhile - and must resolve to a PSGI
triplet. On blocking servers it is awaited inline.

=back

Requests that never reach a handler:

    400  validation failed  - { errors => [ ... ] } (see Open::API/ERRORS)
    404  no matching path
    405  path exists, method does not - with an Allow header
    406  Accept admits none of the responses (negotiate; see NEGOTIATION)
    413  request body over max_body_size
    415  request Content-Type is not declared (negotiate)
    500  the handler died   - { errors => [ { message => $@ } ] }
    501  matched operation has no handler

Every response - handler successes and all of the above alike - is passed
through response finalization: the RFC 7807 rewrite (when C<error_format> is
C<'problem'>), CORS headers for an allowed cross-origin request, and the
security header set. See L</RESPONSE HEADERS>, L</CORS> and L</NEGOTIATION>.

C<< validate_responses => 1 >> additionally checks each response body against
the operation's response schema for that status and turns a mismatch into a
500 carrying the validation errors marked C<< in => 'response' >> - a
development-mode tool, off by default. It applies to Future returns too (the
check runs when the future resolves).

=head2 RESPONSE VALIDATION IN FRONT OF PRODUCTION

Replacing a response with a 500 is right in a dev server and wrong
everywhere else. Report mode weighs the response the same way and then
leaves it alone:

    validate_responses => {
        mode     => 'report',
        report   => sub {
            my ($op_id, $status, $errors, $env) = @_;
            # record it; the client already has the real response
        },
        sample   => 100,           # validate 1 response in N, per operation
        max_body => 1_048_576,     # skip bodies over this
    }

The callback is told which operation, which status, the errors (marked
C<< in => 'response' >>) and the request environment. What the client
receives is what the handler built, byte for byte - status, headers and
body. A callback that dies is warned about and the response is delivered
regardless: a broken reporter loses the sample, never the response.

C<mode> may also be C<'replace'> (the C<1> behaviour) or C<'off'>.
Configuration mistakes croak at C<to_app>: C<'report'> without a callback,
or a mode that is not one of these.

Sampling and the skip rules, and the coverage counters that account for
every response either checked or skipped, are described in
L<Open::API/check_response> and L<Open::API/response_coverage>.

=head1 HOOKS

The optional C<before> and C<after> hooks are each a coderef or a fully
qualified sub name, resolved at C<to_app> time like handlers. The canonical
use is auth:

    my $plack = Open::API::Plack->new(spec => 'openapi.json');
    $plack->before(sub {
        my ($env, $operationId) = @_;
        my $user = check_token($env->{HTTP_AUTHORIZATION})
            or return [ 401, ['Content-Type' => 'application/json'],
                        ['{"errors":[{"message":"unauthorized"}]}'] ];
        $env->{'openapi.user'} = $user;   # visible to the handler
        return;                            # continue
    });
    $plack->after(sub {
        my ($resp, $env, $operationId) = @_;
        # not defined-or: this file claims 5.008003, where // is a syntax
        # error, so the whole module would fail to compile there
        my $rid = $env->{'openapi.rid'};
        push @{ $resp->[1] },
            'X-Request-Id' => defined $rid ? $rid : '-';
        return;
    });

=over 4

=item C<before($env, $operationId)>

Runs after routing (so 404s and 405s never reach it - the operation is known)
and B<before validation> (an unauthorized caller costs no validation work and
gets its 401 rather than a 400). Return a B<reference> to short-circuit the
request: a PSGI triplet is sent as-is, any other reference is JSON-encoded as
a 200. Non-reference returns (including undef) continue to validation. A die
becomes a 500. Stash anything the handler needs into C<$env>.

=item C<after($response, $env, $operationId)>

Runs on every response for a matched operation - handler successes and the
400/500/501 error responses alike (404/405 have no operation, so no hook).
C<$response> is the final PSGI triplet: mutate it in place (add headers, log
C<< $response->[0] >>), or return a new triplet to replace it outright; any
other return value is ignored. A die becomes a 500.

When a handler returns a Future on a non-blocking server, the after hook (and
response validation) are chained onto the future and run when it resolves -
the worker is never blocked.

=back

=head1 SECURITY

The spec's C<securitySchemes> and C<security> requirements are enforced for
you: fill the L</security> map with a checker per scheme name, and each
matched operation's requirements are checked in C before validation or the
C<before> hook run. This is the declarative complement to a hand-written
C<before> hook - the spec already says which operations need which schemes,
so you supply only the verify step.

    $plack->security(
        # scheme name (from components.securitySchemes) => checker
        ApiKey => sub {
            my ($credential, $env, $operationId, $scopes) = @_;
            my $user = lookup_api_key($credential) or return 0;
            return $user;          # truthy = authorized; stashed
        },
        BearerAuth => sub {
            my ($token) = @_;
            verify_jwt($token);    # truthy user object, or 0/undef
        },
    );

The checker receives the extracted C<$credential>, the C<$env>, the
C<$operationId>, and the requirement's C<$scopes> arrayref (the values from the
C<security> entry, C<undef> when none). What is extracted depends on the
scheme type:

=over 4

=item * C<apiKey> - the raw value of the named header, query parameter or
cookie (C<in: header|query|cookie>).

=item * C<http> C<bearer> (and C<oauth2> / C<openIdConnect>, treated as bearer)
- the token after C<Authorization: Bearer >.

=item * C<http> C<basic> - the base64-decoded C<"user:pass"> string.

=back

Return a B<true> value to authorize: it is collected under the scheme name in
C<< $env->{'openapi.auth'} >> (a hashref) and the request proceeds to the
handler. Return false (C<0>, C<undef>, empty string) to reject. A checker that
C<die>s becomes a 500.

Requirements follow the OpenAPI semantics: an operation's C<security> is a
list of alternatives (B<OR>), and the schemes within one alternative are all
required together (B<AND>). The first alternative whose schemes all pass wins.
When none pass the request gets a C<401>; no C<before> hook or handler runs.
An operation-level C<security> overrides the document-level default, and an
explicit empty C<security: []> disables auth for that operation.

Only C<http basic>, C<http bearer>, C<apiKey>, C<oauth2> and C<openIdConnect>
scheme B<types> are supported; a spec that references any other type croaks at
C<Open::API-E<gt>new>. Every scheme any matched operation requires must have a
checker in the L</security> map, or C<to_app> croaks at startup - a missing
checker is a configuration error, never a silent open door. Unsupported flows
(the OAuth2 token exchange itself) are out of scope: you verify an
already-issued token.

L<Open::API::Client> is the mirror image - give it the credentials and it
attaches them automatically. See L<Open::API::Client/SECURITY>.

=head1 CSRF

The C<csrf> option guards every state-changing method (anything other than
GET, HEAD, OPTIONS and TRACE) in C, before validation, the security check or
the C<before> hook run. It combines two defenses:

    $plack->csrf({
        origins => [ 'https://app.example.com' ],  # Origin allowlist
        # a server-side token, verified against your own session/DB store:
        header  => 'X-CSRF-Token',                 # where the token arrives
        cookie  => 'csrf',                         # name used when rotating
        check => sub {
            my ($submitted, $env) = @_;
            my $session = load_session($env);
            my $stored  = delete $session->{csrf} || "";   # atomic take-and-remove
            return 0 unless defined $submitted && $submitted =~ m/^$stored$/;
            my $fresh = random_token();              # your own unguessable value
            $session->{csrf} = $fresh;
            save_session($env, $session);
            return $fresh;                           # framework sets the cookie
       },
    });

=head2 Origin / Referer check

Always on when C<csrf> is given. On an unsafe method the request's C<Origin>
(or C<Referer>, when C<Origin> is absent) must be acceptable, or the request
gets a B<403>. With an C<origins> list the request origin's authority
(host:port) must match one of the listed origins; B<without> a list the
default is same-origin - the origin authority must equal the C<Host> header. A
missing C<Origin> and C<Referer> on an unsafe method is rejected. This is
stateless, needs nothing on the client, and is the whole defense for a modern
C<SameSite> cookie setup - set your session cookie C<SameSite=Lax> or
C<Strict> and the Origin check is belt-and-braces.

=head1 RESPONSE HEADERS

A secure default header set is stamped onto B<every> response - handler
successes and the 4xx/5xx errors alike - suitable for a JSON API:

    X-Content-Type-Options: nosniff
    Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
    X-Frame-Options: DENY
    Referrer-Policy: no-referrer

They are applied B<set-if-absent>, so a handler (or the C<after> hook) that
sets one of these on a particular response keeps the last word. The C<headers>
option overrides the defaults, adds headers, or removes a default by mapping it
to C<undef>:

    $plack->headers({
        'Content-Security-Policy'   => "default-src 'self'",   # override
        'Strict-Transport-Security' => 'max-age=63072000',     # add
        'Referrer-Policy'           => undef,                  # drop a default
    });

Header names match case-insensitively, so C<< 'x-frame-options' => undef >>
removes the default C<X-Frame-Options>. C<Strict-Transport-Security> (HSTS) is
B<not> a default - it only makes sense over HTTPS and can lock a domain out of
plain HTTP, so it is opt-in. To ship nothing but what you list, map each
default to C<undef> (or just override the ones you keep).

=head1 CORS

For a browser API served to a different origin, C<cors> answers preflight
C<OPTIONS> requests and adds C<Access-Control-*> headers to actual responses:

    $plack->cors({
        origins     => [ 'https://app.example.com' ],  # or '*' (the default)
        credentials => 0,                              # allow cookies/auth
        headers     => [ 'Content-Type', 'X-CSRF-Token' ],  # preflight allow
        expose      => [ 'X-Request-Id' ],             # readable by JS
        max_age     => 600,                            # cache the preflight
    });

An C<Origin> is allowed when C<origins> is C<'*'> or lists it exactly (scheme,
host and port). For an allowed request C<Access-Control-Allow-Origin> is set
(the concrete origin, plus C<Vary: Origin>, unless C<origins> is the wildcard),
along with C<Access-Control-Allow-Credentials> when C<credentials> is on and
C<Access-Control-Expose-Headers> from C<expose>. A preflight (an C<OPTIONS>
carrying C<Access-Control-Request-Method> for a path that has no C<OPTIONS>
operation) gets a 204 whose C<Access-Control-Allow-Methods> is the path's
declared methods, with C<Allow-Headers> echoed from the request or taken from
C<headers>, and C<Max-Age> from C<max_age>. C<credentials =E<gt> 1> with a
wildcard origin is refused at C<to_app> - the browser forbids it and it would
be a serious hole, so you must name the origins.

=head1 NEGOTIATION

With C<< negotiate => 1 >> the request path enforces the spec's media types:

=over 4

=item * B<415> when a request carries a body whose C<Content-Type> matches none
of the operation's declared C<requestBody> content types.

=item * B<406> when the request's C<Accept> admits none of the operation's
declared response content types (a C<*/*>, an absent C<Accept>, or an operation
that declares no response types always passes - the check is lenient).

=back

It is off by default because it rejects requests the validator would otherwise
accept (a non-JSON body passes through raw without it). Both checks run in C
before validation.

=head1 ERROR FORMAT

By default an error is C<< { errors => [ ... ] } >> as C<application/json> (see
L<Open::API/ERRORS>). C<< error_format => 'problem' >> instead emits RFC 7807
C<application/problem+json> for every error this layer generates:

    { "type": "about:blank", "title": "Bad Request", "status": 400,
      "detail": "...", "errors": [ ... ] }

C<title> is the status reason phrase, C<detail> the first error's message, and
the original C<errors> array is carried along. Only this layer's own JSON error
envelope is rewritten; a handler that returns its own error body is left
untouched.

=head1 UI

    my $app = Open::API::Plack->new(spec => 'openapi.json', ui => 1)->to_app;

With C<ui> set, C<to_app> wraps the finished app so the documentation UI -
a self-contained Swagger UI clone, see L<Open::API::UI> - answers C<GET>
and C<HEAD> on its own paths before the router runs. The defaults serve
the page at C</docs> (plus its two assets underneath) and the spec JSON at
C</openapi.json>; every other path, and every other method on those paths,
behaves exactly as without the option. A truthy scalar takes the defaults;
a hashref is passed through as L<Open::API::UI/new> options (C<path>,
C<spec_path>, C<title>, C<try_it>, C<headers>):

    $plack->ui({ path => '/documentation', spec_path => '/spec.json' });

The UI is built at C<to_app> time, so problems surface at startup: a
missing L<Template::Stencil> (a recommends, not a prerequisite - the rest
of the distribution never needs it) and a ui path the spec already
declares both croak there.

Two configurations cooperate automatically. The UI's try-it-out script
speaks this app's C<csrf> dialect - the token header and rotation cookie
names are read from L</csrf>, and with an C<origins> allowlist the docs
origin must be listed or try-it-out requests get 403s. And the UI's
responses carry their own header set (a CSP admitting the page's own
script and style); the API's stricter default headers are untouched. See
L<Open::API::UI> for the page itself, its limits, and the routes contract
other frameworks can mount.

=head1 PERFORMANCE

The point of compiling the spec: on the bench in F<bench/openapi.pl> (two
Hyperman workers, wrk, 64 connections, this machine) a fully routed and
validated operation serves B<200,909 req/s against a bare hand-rolled PSGI
ceiling of 202,013 req/s - the whole OpenAPI layer costs about half a
percent>.

=head1 SEE ALSO

L<Open::API>, L<Open::API::Client>, L<Open::API::UI>, L<Plack>,
L<Hyperman>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-open-api at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Open-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Open::API::Plack

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
