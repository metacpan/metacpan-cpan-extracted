package Punk::OAuth2::JWKS;

use 5.024;
use strict;
use warnings;

use Punk::OAuth2;

our $VERSION = '0.03';



1;

__END__

=head1 NAME

Punk::OAuth2::JWKS - a cached JWKS key set

=head1 SYNOPSIS

	my $jwks = Punk::OAuth2::JWKS->new(
		url => 'https://idp.example.com/oauth/jwks.json');

	my $key = $jwks->key_for($c, $kid);   # Crypt::JWS::Key or undef

=head1 DESCRIPTION

Fetches a JWKS document, imports each entry through
L<Crypt::JWS::Key/from_jwk>, and caches C<kid> to key per worker,
implemented in XS. An unknown C<kid> triggers exactly one (rate-limited)
refetch to cover key rotation; a kid still unknown afterwards is
negative-cached so attacker-chosen kids cannot become a fetch stream.
The URL passes the SSRF guard at construction.

You rarely use this directly - L<Punk::OAuth2::Checker/jwt> and the
client's OIDC verification build and drive it for you.

=head1 METHODS

=head2 new

	my $jwks = Punk::OAuth2::JWKS->new(
		url         => 'https://idp.example.com/oauth/jwks.json',
		ttl         => 6 * 3600,   # cache lifetime (default 6h)
		ua          => $agent,     # a Fetch-like agent, optional
		allow_local => 0,          # relax the SSRF guard for loopback
	);

Croaks if the URL fails the SSRF guard (https, resolves to a public
address) unless C<allow_local> is set.

=head2 key_for

	my $key = $jwks->key_for($c, $kid);

Returns the L<Crypt::JWS::Key> for C<$kid>, fetching (via C<< $c->ua >>
or the configured agent) and caching as needed, or undef. C<$c> may be
undef when no request context is available.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
