package Punk::OAuth2::Server;

use 5.024;
use strict;
use warnings;

use Punk::OAuth2;
use Punk::OAuth2::Server::Store;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::OAuth2::Server - an OAuth2/OIDC authorization server

=head1 SYNOPSIS

	oauth2_server '/oauth' => {
		issuer  => 'https://idp.example.com',
		store   => { dsn => 'dbi:SQLite:idp.db' },
		authenticate => 'Auth#require_user',
		consent      => 'Auth#consent',
	};

=head1 DESCRIPTION

The other half of the distribution. Where L<Punk::OAuth2::Provider> logs
your users in somewhere else, this issues the tokens: an OAuth2
authorization server with OpenID Connect flavouring, implemented in XS,
mounted by the C<oauth2_server> keyword.

It serves C</authorize>, C</token>, C</revoke>, C</introspect>,
C</jwks.json> and the RFC 8414 metadata documents. You supply two hooks
- how to authenticate a user and, optionally, how to ask them for
consent - plus a store. Everything else, the whole protocol, is here.

Supported grants are authorization code with PKCE, C<refresh_token> with
rotation, and C<client_credentials>. There is no implicit grant and no
resource owner password grant, and they are not configurable off or on:
both are removed in OAuth 2.1, and a server that cannot perform them
cannot be talked into performing them.

Access tokens are JWTs (RFC 9068 C<at+jwt>) signed with ES256 by
default, so a resource server validates them statelessly with
L<Punk::OAuth2::Checker> and never calls back here. Refresh tokens,
authorization codes and client secrets are opaque random strings, and
the store only ever holds their SHA-256 digests.

=head1 CONSTRUCTOR

=head2 new

	my $server = Punk::OAuth2::Server->new(%opts);

Usually called for you by C<oauth2_server>. An odd number of options
croaks.

=over 4

=item C<issuer> (required)

The issuer URL. It goes in the C<iss> and C<aud> of every access token
and in the metadata, and it is what a resource server checks, so it has
to be the URL clients actually reach.

=item C<store> (required)

Where codes, refresh tokens, clients and consents live. A
L<Punk::OAuth2::Server::Store>, a C<< { dsn => ... } >> hashref, or any
object implementing the same methods. See L</"THE STORE">.

=item C<authenticate>

Coderef or C<'Controller#method'>, called with the context. Returns the
authenticated user id, or a reference - typically a redirect to your
login page - which is returned to the browser as-is. Returning false
denies the authorization. Required in practice: C</authorize> answers
500 without it.

=item C<consent>

Optional. Called as C<< ($c, $client, \@scopes) >> with the client row
and the requested scopes split on spaces. Return true to approve, false
to deny, or a reference to render a consent page. An approval is
recorded, so returning users are not asked again for that client.

=item C<key>

The signing key, a L<Crypt::JWS::Key>. One is generated for C<alg> if
you do not supply one, which is fine for a single process and wrong for
anything that restarts or runs more than one worker - see
L</"THE SIGNING KEY">.

=item C<alg>

Signing algorithm for access tokens. Default C<ES256>.

=item C<at_ttl>

Access token lifetime in seconds. Default 600.

=item C<rt_ttl>

Refresh token lifetime in seconds. Default 2592000 (30 days).

=item C<prefix>

Path the endpoints are mounted under, used to build the metadata URLs.
Default C</oauth>.

=item C<oidc>

Recorded on the server for OIDC behaviour.

=back

=head1 ENDPOINTS

Each takes the Punk context and returns a PSGI triplet, so they can be
mounted as routes directly, which is what C<oauth2_server> does. Every
JSON response carries C<Cache-Control: no-store> and
C<Pragma: no-cache>.

=head2 authorize

	$server->authorize($c);

The authorization endpoint. Reads its parameters from the query string:
C<response_type>, C<client_id>, C<redirect_uri>, C<state>, C<scope>,
C<nonce>, C<code_challenge> and C<code_challenge_method>.

What it does, in order, and the order is the point:

=over 4

=item 1.

Look up C<client_id>, and match C<redirect_uri> exactly against that
client's registered set. Both are required. Failures here answer
B<400 text/plain and do not redirect> - with an unverified redirect
target there is nowhere safe to send an error, and redirecting anyway is
how an authorization server becomes an open redirector.

=item 2.

Require C<< response_type=code >> and PKCE with
C<< code_challenge_method=S256 >>. From here the redirect target is
trusted, so these answer by redirecting back with C<error> and C<state>
(C<unsupported_response_type> and C<invalid_request> respectively).
S256 is the only accepted method: C<plain> is not implemented, so it
cannot be downgraded to.

=item 3.

Call C<authenticate>. A reference is returned to the browser unchanged,
which is how you send the user to a login page. A false return
redirects back with C<access_denied>.

=item 4.

Call C<consent>, unless this user has already consented to this client.
A reference renders your consent page; a false return is
C<access_denied>; a true return is recorded so it is not asked again.

=item 5.

Mint a 32-byte random code bound to the client, user, redirect URI,
scope, nonce and challenge, valid for ten minutes, and redirect back
with C<code>, C<state> and C<iss>.

=back

The C<iss> parameter on the response is RFC 9207, and lets a client
detect a mix-up between two authorization servers.

=head2 token

	$server->token($c);

The token endpoint. Parses an C<application/x-www-form-urlencoded> body
and authenticates the client (see L</"CLIENT AUTHENTICATION">) before
looking at the grant; an unauthenticated client is 401
C<invalid_client> whatever it asked for.

=over 4

=item C<authorization_code>

Consumes the code, which is single-use - the store deletes it on read,
so a replay finds nothing. Then it checks that the code was issued to
this client, has not expired, and was issued for exactly this
C<redirect_uri>, and that S256 of the supplied C<code_verifier> equals
the stored challenge, compared in constant time. Any failure is
C<invalid_grant> with no detail: a client that guessed wrong learns
only that it was wrong.

Returns an access token and a refresh token.

=item C<refresh_token>

Checks the token belongs to this client, is not revoked, and has not
expired, then rotates it: a new refresh token is issued in the same
family and the old one is marked as consumed.

If the presented token was B<already> rotated, that is treated as theft
rather than as a mistake - the legitimate client would be holding the
new token - and the entire family is revoked, logging out the attacker
and the victim together. The response is still a bare
C<invalid_grant>.

=item C<client_credentials>

No user, no refresh token. The access token's C<sub> is the client id.

=back

Anything else is C<unsupported_grant_type>.

=head2 revoke

	$server->revoke($c);

RFC 7009. Client-authenticated, and always answers 200 with an empty
object - revoking an unknown or already-dead token is indistinguishable
from revoking a live one, so the endpoint cannot be used to probe which
tokens exist. Revoking a refresh token kills its whole rotation family.

=head2 introspect

	$server->introspect($c);

RFC 7662. Client-authenticated. An access token is verified locally
against this server's own key and algorithm; a refresh token is looked
up in the store and must be unrevoked, unrotated and unexpired.

A live token answers with C<active> true plus C<sub>, C<scope>,
C<client_id> and C<exp> as available. Everything else - malformed,
expired, revoked, never issued - answers with exactly
C<< {"active":false} >>, so nothing about a token can be learned from
how it is refused.

=head2 jwks

	$server->jwks($c);

The public half of the signing key as a JWKS document, with C<kid>,
C<< use => 'sig' >> and C<alg> set. This is what resource servers fetch
to validate access tokens.

=head2 metadata

	$server->metadata($c);

The RFC 8414 authorization server metadata: the issuer, the five
endpoint URLs built from the issuer and C<prefix>, and the supported
grant types, response types, PKCE methods and signing algorithms. The
plugin serves it at both
C</.well-known/oauth-authorization-server> and
C</.well-known/openid-configuration>.

=head2 prefix

The configured path prefix, defaulting to C</oauth>.

=head1 ACCESS TOKENS

Access tokens are signed JWTs with C<typ> C<at+jwt> (RFC 9068) and the
C<kid> of the signing key, carrying:

	iss        the issuer
	sub        the user id, or the client id for client_credentials
	aud        the issuer
	client_id  the client the token was issued to
	exp / iat  from at_ttl
	jti        a random 16-byte identifier
	scope      when the grant carried one

Because they are verifiable offline, a resource server never talks to
this one on the request path, and the cost of that is the usual one:
a token stays valid until it expires. Keep C<at_ttl> short - the
default is ten minutes - and let the refresh token carry the long-lived
authority, where it can be revoked.

=head1 CLIENT AUTHENTICATION

C</token>, C</revoke> and C</introspect> all authenticate the client
first, by HTTP Basic (URL-decoded, per RFC 6749) or by C<client_id> and
C<client_secret> in the form body. The presented secret is digested and
compared against the stored digest in constant time.

A client registered with no secret is public, and authenticates on its
C<client_id> alone. That is not a weakening: a public client is one that
cannot keep a secret, which is why the authorization code grant requires
PKCE from everybody.

=head1 THE SIGNING KEY

If you do not pass C<key>, one is generated at construction. That is
convenient for a test and wrong for a deployment: a generated key does
not survive a restart, so every previously issued access token becomes
unverifiable, and two workers would sign with two different keys while
publishing one JWKS.

Generate a key once, keep it wherever your other secrets live, and pass
it in:

	oauth2_server '/oauth' => {
		issuer => 'https://idp.example.com',
		key    => Crypt::JWS::Key->from_pem(secret('idp.signing_key')),
		...
	};

=head1 THE STORE

The server itself holds no state. Clients, authorization codes, refresh
tokens and consents all live in the store, and every credential is
digested before it gets there, so a copy of the database yields no
usable token.

L<Punk::OAuth2::Server::Store> is the shipped DBI implementation. Any
object providing the same methods works: C<client_get>, C<code_put>,
C<code_take>, C<refresh_put>, C<refresh_take>, C<refresh_rotate>,
C<refresh_revoke_family>, C<consent_get> and C<consent_put>. Its POD
documents the contract, including which of them must delete and which
must not.

=head1 CAVEATS

The authorization endpoint reads its parameters from the query string
only. The plugin also mounts C<POST /authorize>, but a form-encoded POST
to it is currently answered with 400 C<missing client_id>. Use GET.

=head1 SEE ALSO

L<Punk::Plugin::OAuth2> for the C<oauth2_server> keyword that mounts
this, L<Punk::OAuth2::Server::Store> for the storage contract and
schema, and L<Punk::OAuth2::Checker> for the resource-server side that
validates the tokens issued here.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
