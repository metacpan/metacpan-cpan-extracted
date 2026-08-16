package Punk::OAuth2;

use 5.024;
use strict;
use warnings;
use File::Raw::JSON;
use Crypt::JWS;
use MIME::Base64 ();   # the XS calls MIME::Base64::{en,de}code_base64 by name

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Punk::OAuth2', $VERSION);

1;

__END__

=head1 NAME

Punk::OAuth2 - OAuth2 and OpenID Connect for Punk applications

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	package MyApp;
	use Punk;
	use Punk::Plugin::OAuth2;

	plugin 'OAuth2';

	session secret => secret('session_key'), expires => '7d';

	oauth2 google => {
		preset        => 'google',
		client_id     => secret('oauth.google_id'),
		client_secret => secret('oauth.google_secret'),
		scope         => 'openid email profile',
	};

	oauth2_login '/auth' => {
		on_login => 'Auth#on_login',
		base_url => 'https://app.example.com',
	};

	1;

=head1 DESCRIPTION

Punk::OAuth2 gives a L<Punk> application the client side of OAuth2 and
OpenID Connect: "Log in with ..." against Google, GitHub, or any OIDC
provider, using the authorization code flow with PKCE, signed state,
and id_token verification through L<Crypt::JWS>.

The behaviour lives in L<Punk::Plugin::OAuth2>; this module is the
distribution's version anchor and documentation front door.

=head1 SEE ALSO

L<Punk::Plugin::OAuth2> - the plugin, keywords, and flow reference

L<Crypt::JWS> - the signature engine

L<Punk> - the web framework

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
