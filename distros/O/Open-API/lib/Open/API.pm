package Open::API;

use 5.008003;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Open::API', $VERSION);

Carp::croak(
	"Open::API requires JSON::Schema::Fast built with its C ABI "
	. "(JSON::Schema::Fast 0.04 or later); please upgrade or reinstall it"
) unless _abi_ok();

1;

__END__

=head1 NAME

Open::API - OpenAPI 3.1 server and client

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Open::API;

    # a spec: hashref, JSON text, YAML text, or a filename
    my $api = Open::API->new(spec => 'openapi.json');

    # a PSGI app: operationId => handler (a coderef, or a fully qualified
    # sub name); requests are routed and validated in C before a handler runs
    my $app = $api->to_app(handlers => {
        listPets => 'MyApp::Pets::list',    # resolved once, at to_app time
        getPet   => sub {
            my ($params, $env) = @_;
            my $pet = find_pet($params->{path}{petId});   # already typed
            $pet || [ 404, ['Content-Type' => 'text/plain'], ['gone'] ];
        },
    });

    # the same spec drives a client (see Open::API::Client)
    my $client = Open::API::Client->new(
        api => $api,
        base_url => 'http://127.0.0.1:5000'
    );
    my $res = $client->getPet(petId => 42)->get;

=head1 DESCRIPTION

C<Open::API> loads an OpenAPI 3.1 document once and compiles every parameter,
header, cookie and body schema through L<JSON::Schema::Fast> at
startup. Each request is then routed and validated on a C hot path.

It runs on any PSGI server. On L<Hyperman> a handler may return a Future and
the worker keeps serving other connections while it resolves. The same
compiled object also drives L<Open::API::Client>, a spec-driven HTTP client on
L<Fetch>'s C ABI, so one document defines both sides of the wire.

OpenAPI B<3.1 only>: 3.1 schemas are native JSON Schema 2020-12, which is what
JSON::Schema::Fast validates. A document with any other C<openapi> version
croaks at load.

=head1 CONSTRUCTOR

=head2 new

    my $api = Open::API->new(spec => $spec);

C<spec> is required and may be:

=over 4

=item * a hashref (an already-decoded document),

=item * a string of JSON text,

=item * a string of YAML text (decoded with L<YAML::XS>, loaded lazily -
only YAML specs need it), or

=item * a filename (C<.json>, C<.yaml> or C<.yml>; anything else is sniffed by
content).

=back

Compilation walks C<paths> once: every operation needs a unique
C<operationId> (it is the dispatch key), path templates are pre-split,
path-item and operation C<parameters> are merged (operation wins), and every
schema is compiled through the JSF ABI - parameters with coercion enabled
(string sources satisfy typed schemas, exactly what OpenAPI parameters need)
and C<default>-filling on. C<$ref>s to C<#/components/schemas/...> are
resolved at compile time. A malformed document, a missing or duplicate
operationId, or an unresolvable reference croaks here, at startup.

=head1 THE PSGI APP

=head2 to_app

    my $app = $api->to_app(
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
    );

Returns a PSGI coderef whose request path runs in C: route the method and
path, validate and assemble every declared input, then call

    $handlers->{$operationId}->(\%params, $env);

A handler is a coderef, or a B<fully qualified sub name> as a string
(C<'MyApp::listPets'>) - names are resolved once, at C<to_app> time, so a typo
croaks at startup rather than surfacing per request:

    my $app = $api->to_app(handlers => {
        listPets => 'MyApp::Pets::list',
        getPet   => \&MyApp::Pets::get,
    });

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

    400  validation failed  - { errors => [ ... ] } (see ERRORS)
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

=head1 HOOKS

C<to_app> takes optional C<before> and C<after> hooks - each a coderef or a
fully qualified sub name, resolved at C<to_app> time like handlers. The
canonical use is auth:

    my $app = $api->to_app(
        handlers => \%handlers,
        before   => sub {
            my ($env, $operationId) = @_;
            my $user = check_token($env->{HTTP_AUTHORIZATION})
                or return [ 401, ['Content-Type' => 'application/json'],
                            ['{"errors":[{"message":"unauthorized"}]}'] ];
            $env->{'openapi.user'} = $user;   # visible to the handler
            return;                            # continue
        },
        after    => sub {
            my ($resp, $env, $operationId) = @_;
            push @{ $resp->[1] }, 'X-Request-Id' => $env->{'openapi.rid'} // '-';
            return;
        },
    );

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
you: give C<to_app> a C<security> map of scheme name to a checker, and each
matched operation's requirements are checked in C before validation or the
C<before> hook run. This is the declarative complement to a hand-written
C<before> hook - the spec already says which operations need which schemes,
so you supply only the verify step.

    my $app = $api->to_app(
        handlers => \%handlers,
        security => {
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
C<new>. Every scheme any matched operation requires must have a checker in the
C<security> map, or C<to_app> croaks at startup - a missing checker is a
configuration error, never a silent open door. Unsupported flows (the OAuth2
token exchange itself) are out of scope: you verify an already-issued token.

L<Open::API::Client> is the mirror image - give it the credentials and it
attaches them automatically. See L<Open::API::Client/SECURITY>.

=head1 CSRF

C<to_app> takes a C<csrf> option that guards every state-changing
method (anything other than GET, HEAD, OPTIONS and TRACE) in C, before
validation, the security check or the C<before> hook run. It combines two
defenses:

    my $app = $api->to_app(
        handlers => \%handlers,
        csrf => {
            origins => [ 'https://app.example.com' ],  # Origin allowlist
            # a server-side token, verified against your own session/DB store:
            header  => 'X-CSRF-Token',                 # where the token arrives
            cookie  => 'csrf',                         # name used when rotating
            check => sub {
                my ($submitted, $env) = @_;
                my $session = load_session($env);
                my $stored  = delete $session->{csrf} || "";   # atomic take-and-remove
                return 0 unless defined $submited && $submitted =~ m/^$stored$/;
                my $fresh = random_token();              # your own unguessable value
                $session->{csrf} = $fresh;
                save_session($env, $session);
                return $fresh;                           # framework sets the cookie
           },
        },
    );

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

    headers => {
        'Content-Security-Policy'   => "default-src 'self'",   # override
        'Strict-Transport-Security' => 'max-age=63072000',     # add
        'Referrer-Policy'           => undef,                  # drop a default
    }

Header names match case-insensitively, so C<< 'x-frame-options' => undef >>
removes the default C<X-Frame-Options>. C<Strict-Transport-Security> (HSTS) is
B<not> a default - it only makes sense over HTTPS and can lock a domain out of
plain HTTP, so it is opt-in. To ship nothing but what you list, map each
default to C<undef> (or just override the ones you keep).

=head1 CORS

For a browser API served to a different origin, C<cors> answers preflight
C<OPTIONS> requests and adds C<Access-Control-*> headers to actual responses:

    cors => {
        origins     => [ 'https://app.example.com' ],  # or '*' (the default)
        credentials => 0,                              # allow cookies/auth
        headers     => [ 'Content-Type', 'X-CSRF-Token' ],  # preflight allow
        expose      => [ 'X-Request-Id' ],             # readable by JS
        max_age     => 600,                            # cache the preflight
    }

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
L</ERRORS>). C<< error_format => 'problem' >> instead emits RFC 7807
C<application/problem+json> for every error this layer generates:

    { "type": "about:blank", "title": "Bad Request", "status": 400,
      "detail": "...", "errors": [ ... ] }

C<title> is the status reason phrase, C<detail> the first error's message, and
the original C<errors> array is carried along. Only this layer's own JSON error
envelope is rewritten; a handler that returns its own error body is left
untouched.

=head1 METHODS

=head2 spec

The decoded OpenAPI document.

=head2 operations

    my $ops = $api->operations;   # [ { operationId, method, path }, ... ]

=head2 operation

    my $info = $api->operation('getPet');

A description of one operation: C<params> by location (name + required),
C<body> (required flag + content types) and C<responses> (statuses with
compiled schemas). C<undef> for an unknown id.

=head2 match

    my ($opId, $captures) = $api->match($method => $path);

The router alone: C<($operationId, \%raw_path_captures)> on a match; an empty
list for a 404; C<(undef, \@allow)> when the path exists but the method does
not (a 405 and its Allow list). For framework adapters.

=head2 validate_request

    my ($ok, $result) = $api->validate_request($opId, {
        path   => \%raw_captures,
        query  => $query_string_or_hashref,
        header => \%lowercased_headers,
        body   => $raw_body_or_decoded_ref,
    });

The validator alone: C<(1, \%params)> or C<(0, \@errors)>. Header names must
be lowercased by the caller; cookies are parsed from the C<cookie> header when
the operation declares cookie parameters. For framework adapters - together
with L</match> this is the complete integration surface, everything heavy
stays in C.

=head1 ERRORS

Validation errors are hashrefs: the L<JSON::Schema::Fast> output fields
(C<instanceLocation>, C<keyword>, C<schemaLocation>, C<message>) augmented
with C<in> (path / query / header / cookie / body / response) and C<name>
(the parameter name). Missing required inputs use C<< keyword => 'required' >>;
an undecodable JSON body uses C<< keyword => 'json' >>.

=head1 PERFORMANCE

The point of compiling the spec: on the bench in F<bench/openapi.pl> (two
Hyperman workers, wrk, 64 connections, this machine) a fully routed and
validated operation serves B<200,909 req/s against a bare hand-rolled PSGI
ceiling of 202,013 req/s - the whole OpenAPI layer costs about half a
percent>..

=head1 ARCHITECTURE

Open::API is a consumer of two runtime-resolved C ABIs, the same DBI-style
versioned function-pointer tables used across the Semantic stack:

=over 4

=item * L<JSON::Schema::Fast> (required) - schemas are compiled once through
C<jsf_abi.h> and every validation on the request path is a direct C call.
Resolved and version-checked at load; absence is a hard error.

=item * L<Fetch> (optional) - L<Open::API::Client> fires requests through
C<fetch_abi.h>. Resolved lazily on first client construction; the server side
never loads it.

=back

There is no link-time coupling: each distribution builds and upgrades
independently, and a version skew fails cleanly at boot (t/12-abi-guard.t).

=head1 SEE ALSO

L<Open::API::Client>, L<JSON::Schema::Fast>, L<Fetch>, L<Hyperman>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-open-api at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Open-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Open::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Open-API>

=item * Search CPAN

L<https://metacpan.org/release/Open-API>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
