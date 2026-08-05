package Open::API::Client;

use 5.008003;
use strict;
use warnings;
use Open::API;   # loads the shared XS

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Open::API::Client - a spec driven HTTP client using Fetch

=head1 SYNOPSIS

    my $client = Open::API::Client->new(
        spec     => 'openapi.json',      # or api => $open_api
        base_url => 'http://127.0.0.1:3000',
    );

    my $res = $client->call('getPet', petId => 42)->get;
    # { status => 200, headers => {...}, data => { id => 42, ... } }

    # operationId sugar (same as call):
    $res = $client->getPet(petId => 42)->get;

=head1 DESCRIPTION

Builds requests from the same compiled OpenAPI 3.1 document the server side
uses: parameters are validated client-side through the compiled
L<JSON::Schema::Fast> handles BEFORE any I/O (bad input croaks), the URL,
query, headers, cookies and JSON body are assembled in C, and the request is
fired through L<Fetch>'s C ABI. Every call returns a L<Fetch::Future>: C<get>
awaits it synchronously, or pass C<< loop => >> at construction to share an
event loop and run calls concurrently.

The future resolves to a hashref: C<status>, C<headers> (lowercased names),
C<data> (JSON-decoded body when the response is C<application/json>, raw bytes
otherwise), and on failure C<error> (with C<status> 0 for transport errors).
With C<< validate => 1 >>, a response that does not match the operation's
response schema gets C<error> and C<errors> set.

=head1 CONSTRUCTOR

    Open::API::Client->new(%opts);

C<api> (an L<Open::API>) or C<spec> (anything L<Open::API/new> accepts) is
required, as is C<base_url>. C<validate> (default 0) checks response bodies
against the spec. All other options are passed to L<Fetch>'s constructor on
first use, so everything the UA supports works here:

    my $client = Open::API::Client->new(
        spec       => 'openapi.json',
        base_url   => 'https://api.example.com',
        cookie_jar => 1,                                # capture + replay cookies
        headers    => { Authorization => "Bearer $t" }, # on every request
        agent      => 'MyApp/1.0',
        timeout    => 10,
        tls_verify => 1,
        pool_size  => 64,
        loop       => $shared_loop,                     # async on one loop
    );

The cookie jar captures C<Set-Cookie> from responses and replays cookies on
later calls automatically; default C<headers> are merged under any parameters
the operation declares. Two sharp edges: per-call values are matched to
B<declared> parameter names only (undeclared C<%params> keys are ignored - put
undeclared headers such as C<Authorization> in the UA C<headers>), and when an
operation declares C<cookie> parameters the built C<Cookie> header takes the
place of the jar's cookies for that call.

The C<security> option (see L</SECURITY>) is spec-driven authentication: give
it the credentials once and each call attaches whatever the operation's
C<security> requirements ask for.

The C<csrf> option (see L</CSRF>) makes a CSRF-protected server work with no
per-call code.

=head1 CSRF

If the server enforces CSRF (see L<Open::API/CSRF>), C<< csrf => 1 >> makes the
client satisfy it transparently:

    my $client = Open::API::Client->new(
        spec       => 'openapi.json',
        base_url   => 'https://api.example.com',
        cookie_jar => 1,     # carry the session cookie
        csrf       => 1,     # handle the CSRF handshake
    );

    $client->listPets->get;                       # a safe call seeds the token
    $client->createPet(body => \%pet)->get;       # POST just works

On a state-changing method (POST/PUT/PATCH/DELETE) the client presents the
C<Origin> the server checks and echoes the current CSRF token in the token
header; from each response it captures the token the server sets, so it
follows single-use rotation on its own. Do a safe call first (the usual "load
the page" request) so the server can hand out the initial token. C<cookie_jar>
carries the session cookie the token is bound to.

C<< csrf => 1 >> uses the defaults C<< { cookie => 'csrf', header =>
'X-CSRF-Token', origin => <derived from base_url> } >>; pass a hashref to
override any of them:

    csrf => { header => 'X-XSRF-Token', cookie => 'xsrf',
              origin => 'https://app.example.com' },

=head1 SECURITY

Pass a C<security> map of scheme name (from the spec's
C<components.securitySchemes>) to a credential, and every call attaches what
its operation requires - the mirror image of the server's checker map:

    my $client = Open::API::Client->new(
        spec     => 'openapi.json',
        base_url => 'https://api.example.com',
        security => {
            ApiKey     => $api_key,             # apiKey: header/query/cookie
            BearerAuth => $access_token,        # http bearer / oauth2 / oidc
            BasicAuth  => [ $user, $password ], # http basic (or "user:pass")
        },
    );

    $client->getPet(petId => 42)->get;   # credentials attached automatically

How each credential is sent follows its scheme: an C<apiKey> goes in the named
header, query parameter or cookie; a C<bearer> (or C<oauth2> /
C<openIdConnect>) token becomes C<Authorization: Bearer $token>; a C<basic>
credential - a C<"user:pass"> string or a C<< [ $user, $pass ] >> pair - is
base64-encoded into C<Authorization: Basic ...>.

When an operation lists several alternatives (an B<OR>), the client uses the
first one whose schemes are all present in the C<security> map; an B<AND>
alternative attaches every scheme in it. If no alternative can be satisfied
from the credentials you supplied, the call croaks B<before> any I/O rather
than firing an unauthenticated request. Operations with no security
requirement send nothing extra.

One scheme type is exempt from that croak: an C<apiKey> B<in a cookie> (a
session cookie set at login, say) is ambient - the L<cookie jar|/CONSTRUCTOR>
carries it - so the client does not require an explicit credential for it and
does not attach one unless you pass it. Enable C<cookie_jar> and log in first;
the session cookie then satisfies the scheme on its own. Every other scheme
(header/query C<apiKey>, C<bearer>, C<basic>) is not ambient and must be in the
C<security> map.

=head1 METHODS

=head2 call

    my $future = $client->call($operationId, %params);

Flat C<%params> are matched to the operation's declared parameters by name
(C<body> is the request body). Croaks before any I/O when a required
parameter is missing or a value fails its schema.

=head2 api

The underlying L<Open::API> object.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
