package Punk::OAuth2::Checker;

use 5.024;
use strict;
use warnings;
use Punk::OAuth2;
use Punk::OAuth2::JWKS;
use Crypt::JWS::Key;
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::OAuth2::Checker - resource server bearer token checkers

=head1 SYNOPSIS

	use Punk::OAuth2::Checker;

	my $jwt = Punk::OAuth2::Checker->jwt(
		issuer   => 'https://idp.example.com',
		jwks_url => 'https://idp.example.com/oauth/jwks.json',
		audience => 'https://api.example.com',
		algs     => ['RS256', 'ES256'],
	);

	# the OpenAPI security map (checker is the house contract)
	$scope->api('openapi.json' => { security => { oauth => $jwt } });

	# a plain route guard emitting RFC 6750 WWW-Authenticate
	under '/api' => Punk::OAuth2::Checker->guard($jwt,
	                                             scopes => ['read:books']);

=head1 DESCRIPTION

Validates incoming C<Bearer> access tokens, implemented in XS. The two
factories return a checker coderef matching the OpenAPI security-map
contract - C<< $checker->($credential, $c, $operationId, $scopes) >>
returning the claims hashref or false - and C<guard> returns a route
guard. This module is the loader and the manual; the methods and the
checker/guard closures are XS.

=head2 jwt (%opts)

	my $jwt = Punk::OAuth2::Checker->jwt(
		issuer   => 'https://idp.example.com',
		jwks_url => 'https://idp.example.com/oauth/jwks.json',
		audience => 'https://api.example.com',
		algs     => ['RS256', 'ES256'],   # allowlist
		leeway   => 60,
	);
	# ...or a static key instead of jwks_url:
	my $jwt = Punk::OAuth2::Checker->jwt(
		issuer => ..., audience => ..., key => $pem_or_secret);

Local JWT validation: C<jwks_url> (keys fetched and cached via
L<Punk::OAuth2::JWKS>) or a static C<key> (a L<Crypt::JWS::Key>, a PEM
string, or an HS shared secret). Checks the algorithm allowlist before
any crypto, then the signature, then C<issuer> (exact), C<audience>
(the C<aud> claim must contain it), C<exp>/C<nbf> with C<leeway>, and the
required scopes against the C<scope> string or C<scp> array. Returns a
checker coderef.

=head2 introspect (%opts)

	my $intro = Punk::OAuth2::Checker->introspect(
		url           => 'https://idp.example.com/oauth/introspect',
		client_id     => 'my-api',
		client_secret => 's3cr3t',
		cache_ttl     => 60,
	);

RFC 7662 introspection: POSTs the token to C<url> with client
credentials, requires C<< active: true >>, and caches the result for
C<cache_ttl> seconds keyed by the token's SHA-256 (never the raw token).
Returns a checker coderef.

=head2 guard ($checker, %opts)

	under '/api' => Punk::OAuth2::Checker->guard($jwt,
		scopes => ['read:books'], realm => 'books-api');

	# in a handler behind the guard:
	get '/api/books' => sub {
		my ($c) = @_;
		my $sub = $c->stash->{auth}{oauth}{sub};
		...
	};

Wraps a checker as a plain route guard. It extracts the C<Bearer>
credential itself and, on denial, returns a 401 (C<invalid_token>) or
403 (C<insufficient_scope>) with an RFC 6750 C<WWW-Authenticate> header.
C<scopes> lists the required scopes; C<scheme> names the stash slot
(default C<oauth>); C<realm> sets the challenge realm.

On success the claims land in C<< $c->stash->{auth}{$scheme} >>; on
failure the reason is in C<< $c->stash->{'punk.oauth2.error'} >>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
