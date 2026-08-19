package Punk::OAuth2::Provider;

use 5.024;
use strict;
use warnings;

use Punk::OAuth2;   # the XS core installs this package's methods

our $VERSION = '0.04';


1;

__END__

=head1 NAME

Punk::OAuth2::Provider - one configured OAuth2/OIDC provider

=head1 SYNOPSIS

	# the usual route: the oauth2 keyword builds one of these for you
	oauth2 google => { preset => 'google', client_id => '...' };

	# built directly, and driven by hand
	my $p = Punk::OAuth2::Provider->new(google =>
		preset        => 'google',
		client_id     => $id,
		client_secret => $secret,
	);

	$p->ensure_endpoints($c);

	my $url = $p->authorize_url(
		redirect_uri => 'https://app.example.com/auth/google/callback',
		state        => $state,
		nonce        => $nonce,
		challenge    => $challenge,
	);

	my $tokens   = $p->exchange($c, code => $code,
	                                redirect_uri => $redirect_uri,
	                                verifier     => $verifier,
	                                nonce        => $nonce);
	my $identity = $p->identity($c, $tokens);

=head1 DESCRIPTION

A provider is one entry in your OAuth2 configuration made executable:
where to send the user, how to trade the code for tokens, and how to
turn the answer into an identity you can trust. It is a blessed hashref
of the merged configuration, and every method is implemented in XS.

Normally you never construct one. L<Punk::Plugin::OAuth2> builds a
provider per C<oauth2> declaration and drives it from the login routes,
which is where the session state, PKCE and redirect handling live. The
class is documented because it is also usable on its own - for a flow
the plugin does not mount, a background token refresh, or a test - and
because its behaviour is what the plugin's security guarantees rest on.

The security-relevant behaviour is in L</"ENDPOINT DISCOVERY">,
L</"THE SSRF GUARD"> and L</"ID TOKEN VERIFICATION">.

=head1 CONSTRUCTOR

=head2 new

	my $p = Punk::OAuth2::Provider->new($name, %config);

C<$name> is the local name for this provider, the one that appears in
route paths and in the C<provider> field of an identity. The rest is a
flat list of configuration pairs, not a hashref; an odd number of them
croaks.

If C<%config> contains C<preset>, that preset is laid down first and
the rest of C<%config> is merged over it key by key. See
L<Punk::OAuth2::Presets>.

Recognised keys, beyond whatever a preset supplied:

=over 4

=item C<client_id>

Required. Everything else has either a default or a preset behind it;
this does not.

=item C<client_secret>

Omit it only for a public client, which must then say so with
C<< public => 1 >>. An OIDC provider with neither croaks at
construction rather than failing later at the token endpoint.

=item C<issuer>

The provider's issuer identifier. Required when C<discovery> is on,
where it is both the base for the discovery URL and the value the
document must agree with. Also the value C<iss> is checked against in
every id_token.

=item C<discovery>

Fetch the endpoints from the issuer's discovery document instead of
configuring them. Default off. See L</"ENDPOINT DISCOVERY">.

=item C<authorization_endpoint> / C<token_endpoint>

Required unless C<discovery> is on. Anything else configured explicitly
is kept as-is and never overwritten by discovery.

=item C<jwks_uri>

Where the signing keys live. Without it there is no key set, and an
OIDC login can only verify an id_token if the C<algs> allowlist permits
HMAC (see L</"ID TOKEN VERIFICATION">).

=item C<userinfo_endpoint>

Recorded from configuration or discovery. Identity is taken from the
id_token, so this is not called during a normal login.

=item C<identity_endpoint> / C<emails_endpoint> / C<identity_map>

The plain-OAuth2 path: where to fetch the user, optionally where to
fetch their addresses, and how to normalize the result. Documented
under L<Punk::OAuth2::Presets/"IDENTITY MAPPING">.

=item C<oidc>

Whether this provider issues id_tokens. Presets set it; set it yourself
for a hand-configured provider.

=item C<scope>

Space-separated scope string. Defaults to empty, in which case no
C<scope> parameter is sent at all.

=item C<auth_method>

How client credentials reach the token endpoint: C<basic> (the default,
HTTP Basic) or C<body> (form fields).

=item C<algs>

Signature algorithms accepted on an id_token. Defaults to
C<['RS256', 'ES256']>. This is an allowlist, and it is the only thing
that enables HMAC verification.

=item C<leeway>

Clock skew allowed on C<exp> and C<iat>, in seconds. Default 60.

=item C<authorize_params>

Extra static query parameters merged into every authorization URL, as a
hashref. This is where provider-specific extras go: C<prompt>,
C<access_type>, C<hd> and so on.

=item C<token_headers>

Extra headers sent with the token request, as a hashref.

=item C<allow_local>

Relax the SSRF guard for a loopback identity provider. For development
and tests. See L</"THE SSRF GUARD">.

=item C<public>

Declares a client with no secret. PKCE still applies; this only
suppresses the missing-secret check.

=item C<ua>

The HTTP agent, or a coderef returning one. See
L</"THE USER AGENT">.

=back

Construction validates rather than deferring: a missing C<client_id>,
an unsafe or absent C<issuer> under discovery, missing endpoints
without discovery, or an OIDC provider with no secret and no C<public>
flag all croak here, at declaration time, rather than on the first user
who tries to log in.

=head1 ACCESSORS

=head2 name

The local name this provider was declared under.

=head2 issuer

The configured issuer, or undef.

=head2 scope

The scope string, empty rather than undef when none was set.

=head2 oidc

True if this provider issues id_tokens.

=head1 METHODS

Every method that talks to the network takes the Punk context C<$c> as
its first argument, and uses it to find an agent (see L</"THE USER
AGENT">). Under Hyperman these calls park the worker rather than
blocking it.

=head2 ensure_endpoints

	$p->ensure_endpoints($c);

Makes sure C<authorization_endpoint> and C<token_endpoint> are known,
running discovery if they are not. Returns nothing, croaks on failure,
and does nothing at all when both are already set - so it is cheap to
call before every use, which is what the login routes do.

=head2 jwks

	my $jwks = $p->jwks;

The L<Punk::OAuth2::JWKS> key set for C<jwks_uri>, or undef if there is
no C<jwks_uri>. Built once and cached on the provider, so the key set's
own caching and negative caching apply across every login.

=head2 authorize_url

	my $url = $p->authorize_url(
		redirect_uri => $uri,
		state        => $state,
		nonce        => $nonce,
		challenge    => $challenge,
	);

The URL to send the user to. Always carries C<response_type=code> and
C<client_id>; adds C<scope> when non-empty, C<state> and
C<redirect_uri> when given, and C<nonce> when given B<and> this is an
OIDC provider. A C<challenge> becomes C<code_challenge> plus
C<code_challenge_method=S256> - S256 is the only method offered, so
there is no downgrade to plain to negotiate.

Any C<authorize_params> are merged in, and can override the parameters
above. Parameters are sorted by name and percent-encoded, and the
separator is chosen by looking for an existing query string, so an
endpoint that already carries one still produces a valid URL.

=head2 exchange

	my $tokens = $p->exchange($c, code         => $code,
	                              redirect_uri => $uri,
	                              verifier     => $verifier,
	                              nonce        => $nonce);

Trades an authorization code for tokens, returning a
L<Punk::OAuth2::Tokens>. C<verifier> is the PKCE code verifier and
C<nonce> the value issued in the authorization request.

For an OIDC provider this also verifies the returned id_token and
stores the verified claims on the tokens as C<id_claims>. Verification
failure croaks: a login that cannot prove who it is for does not
proceed with an unverified one.

Croaks if the token endpoint answers non-200 or returns no
C<access_token>, quoting the provider's own C<error> field when it sent
one.

=head2 refresh

	my $tokens = $p->refresh($c, $refresh_token);
	my $tokens = $p->refresh($c, $old_tokens);

Runs the refresh_token grant. Accepts either the token string or a
L<Punk::OAuth2::Tokens> to take it from, and croaks if there is nothing
to refresh. Returns a fresh Tokens object.

Note that this does not verify an id_token even when the provider
returns one; use L</verify_id_token> if you need the new claims.

=head2 verify_id_token

	my $claims = $p->verify_id_token($c, $id_token, nonce => $nonce);

Verifies an id_token and returns its claims as a hashref, or C<undef>
if anything about it fails to check out. Pass the C<nonce> you issued
so it can be compared. See L</"ID TOKEN VERIFICATION">.

The undef return is deliberate: there is exactly one answer for every
kind of failure, so nothing about the token can be inferred from how it
was rejected.

=head2 identity

	my $identity = $p->identity($c, $tokens);

The normalized identity behind a set of tokens:

	{ provider, sub, email, email_verified, name, picture, raw }

For an OIDC provider this reads the verified C<id_claims> left by
L</exchange> and croaks if they are absent, so an identity can never be
built from an unverified token. C<email_verified> is normalized to 1 or
0.

For a plain OAuth2 provider it calls C<identity_endpoint> with the
access token, plus C<emails_endpoint> if configured, and passes both
through C<identity_map>. Without a map it falls back to reading C<sub>
(or C<id>), C<email> and C<name> off the response.

C<raw> is always the provider's untouched payload - the claims or the
user response - so nothing normalization drops is actually lost.

=head1 ENDPOINT DISCOVERY

With C<< discovery => 1 >>, the endpoints come from
C<$issuer/.well-known/openid-configuration>, fetched once on the first
L</ensure_endpoints> and then kept on the provider.

The document is not taken at its word:

=over 4

=item *

Its C<issuer> must equal the configured C<issuer>, compared exactly
apart from a single trailing slash on either side. A document that
names a different issuer is rejected rather than followed, which is
what stops a compromised or misconfigured discovery URL from pointing
a login at someone else's endpoints.

=item *

Every endpoint it offers is put through L</"THE SSRF GUARD"> before it
is stored, and an unsafe one croaks rather than being skipped.

=item *

Anything you configured explicitly wins. Discovery only fills in
C<authorization_endpoint>, C<token_endpoint>, C<jwks_uri> and
C<userinfo_endpoint> that are still missing, so pinning one endpoint by
hand is always possible.

=item *

C<authorization_response_iss_parameter_supported> is recorded as
C<iss_param>, so the callback can check the C<iss> the provider echoes
back (RFC 9207).

=back

If the document arrives but still leaves the authorization or token
endpoint unset, that croaks too.

=head1 THE SSRF GUARD

Discovery means fetching a URL a third party chose, so every URL that
arrives that way is checked before it is used. By default:

=over 4

=item *

C<https> only.

=item *

No credentials in the URL.

=item *

No loopback host.

=item *

The host is resolved, and every address it resolves to is checked: if
any is private, the URL is refused. Checking all of them, rather than
just the first, is what makes DNS entries that mix a public and a
private answer useless.

=back

C<< allow_local => 1 >> relaxes this to "https anywhere, or http to
loopback", which is what a local identity provider in development or a
test suite needs. It stays off by default because it is exactly the
check that stops discovery from reaching into a private network.

=head1 ID TOKEN VERIFICATION

Two steps, both required.

First the signature. With a C<jwks_uri>, the token's unverified header
is peeked for its C<kid>, the key is resolved from the key set, and
L<Crypt::JWS> verifies against it with C<algs> as the allowlist. With
no key set, the C<client_secret> can serve as an HMAC key - but only if
C<algs> actually contains an C<HS*> algorithm. Since the default is
C<RS256> and C<ES256>, a provider that ought to be using public keys
cannot be talked into accepting a token signed with the client secret.

Then the claims, over the decoded payload:

=over 4

=item *

C<iss> must equal the configured issuer, up to a single trailing slash.

=item *

C<aud> must contain C<client_id>, whether it is a string or an array.

=item *

C<azp> is required when there is more than one audience, and must be
C<client_id>.

=item *

C<exp> is required, and checked against now with C<leeway>.

=item *

C<iat>, if present, must not be in the future by more than C<leeway>.

=item *

C<nonce> must match the one issued, compared in constant time. Only
checked when a nonce was actually issued.

=back

Any failure at any point yields C<undef>, with no indication of which
check it was.

=head1 THE USER AGENT

Requests go through, in order: the C<ua> configuration if it is an
object; C<ua> called with C<$c> if it is a coderef; C<< $c->ua >>; and
failing all of those, a L<Fetch> agent with a 10 second timeout that
the provider builds once and keeps.

Passing C<ua> is the seam the test suite uses to run whole login flows
against an in-process identity provider without a socket. A coderef is
the form to use when the agent should come from the request rather than
from the declaration.

=head1 SEE ALSO

L<Punk::Plugin::OAuth2> for the C<oauth2> declaration and the login
routes that drive this class, L<Punk::OAuth2::Presets> for the bundled
provider configurations, L<Punk::OAuth2::Tokens> for what C<exchange>
and C<refresh> return, and L<Punk::OAuth2::JWKS> for key fetching and
caching.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
