package Punk::OAuth2::Presets;

use 5.024;
use strict;
use warnings;

use Punk::OAuth2;

our $VERSION = '0.03';

1;

__END__

=head1 NAME

Punk::OAuth2::Presets - provider presets for Punk::OAuth2

=head1 SYNOPSIS

	package MyApp;
	use Punk;
	use Punk::Plugin::OAuth2;

	plugin 'OAuth2';

	# a preset supplies the endpoints; you supply the credentials
	oauth2 google => {
		preset        => 'google',
		client_id     => secret('oauth.google_id'),
		client_secret => secret('oauth.google_secret'),
	};

	# any preset field can be replaced alongside it
	oauth2 github => {
		preset        => 'github',
		scope         => 'read:user user:email repo',
		client_id     => secret('oauth.github_id'),
		client_secret => secret('oauth.github_secret'),
	};

	# the config a preset expands to, if you want to see it
	my $cfg = Punk::OAuth2::Presets::preset('google');

=head1 DESCRIPTION

A preset is a named bundle of provider configuration: the endpoints,
default scope and client-authentication style for a provider whose
details are fixed and public, so that declaring it takes a client id
and secret rather than six URLs copied from someone's documentation.

Presets are built in C (F<include/pox/pox_presets.h>) and handed to the
provider constructor, which merges them under your own configuration.
Nothing here is required: a provider declared without C<preset> works
exactly the same way, you just write the endpoints out yourself.

=head1 FUNCTIONS

=head2 preset

	my $cfg = Punk::OAuth2::Presets::preset($name);

Returns a fresh hashref of configuration for C<$name>, which is
C<google>, C<github> or C<oidc>. Not exported, and rarely called
directly - the usual route is C<< preset => $name >> in a provider
declaration, which calls this for you. The hashref is newly built on
every call, so modifying it cannot affect any other provider.

Croaks on an unknown name.

=head1 PRESETS

=head2 google

OpenID Connect against Google, with the endpoints hard-coded rather
than discovered, so a login costs no discovery round trip:

	oidc                    1
	issuer                  https://accounts.google.com
	authorization_endpoint  https://accounts.google.com/o/oauth2/v2/auth
	token_endpoint          https://oauth2.googleapis.com/token
	jwks_uri                https://www.googleapis.com/oauth2/v3/certs
	userinfo_endpoint       https://openidconnect.googleapis.com/v1/userinfo
	scope                   openid email profile
	auth_method             body

Identity comes from the verified C<id_token>, as for any OIDC provider.

=head2 github

GitHub is not an OpenID Connect provider: there is no C<id_token> and
no C<jwks_uri>, so identity is fetched from the user API with the
access token instead.

	oidc                    0
	authorization_endpoint  https://github.com/login/oauth/authorize
	token_endpoint          https://github.com/login/oauth/access_token
	identity_endpoint       https://api.github.com/user
	emails_endpoint         https://api.github.com/user/emails
	scope                   read:user user:email
	auth_method             body
	token_headers           { Accept => 'application/json' }
	identity_map            \&Punk::OAuth2::_github_identity

C<token_headers> is not decoration: GitHub's token endpoint answers in
C<application/x-www-form-urlencoded> unless asked for JSON.

The separate C<emails_endpoint> exists because C<GET /user> omits the
email address whenever the account keeps it private, which is the
default. See L</"IDENTITY MAPPING"> for how the two responses are
combined.

=head2 oidc

The generic case - no endpoints at all, just the two switches that
tell the provider to find them itself:

	oidc                    1
	discovery               1

Set C<issuer> alongside it and everything else is read from that
issuer's RFC 8414 / OpenID Connect discovery document. This is the
preset to reach for with any standards-compliant identity provider
that is not Google.

	oauth2 corp => {
		preset        => 'oidc',
		issuer        => 'https://idp.corp.example',
		client_id     => '...',
		client_secret => '...',
	};

=head1 OVERRIDING

The provider constructor lays the preset down first and then your
configuration on top, key by key, with the C<preset> key itself
dropped. So any field above can simply be named again in the
declaration to replace it:

	oauth2 github => {
		preset      => 'github',
		scope       => 'read:user user:email repo',   # replaces the default
		client_id   => '...',
	};

The merge is flat, not deep. Giving your own C<token_headers> replaces
the preset's hashref outright rather than adding to it, so carry over
any part of it you still want:

	token_headers => { Accept => 'application/json', 'X-Trace' => $id },

Fields no preset sets are filled in afterwards by the provider itself:
C<auth_method> defaults to C<basic>, C<algs> to C<RS256> and C<ES256>,
C<leeway> to 60 seconds, C<scope> to empty and C<discovery> to off.
That is why the two presets that want C<auth_method> set it explicitly.

=head1 IDENTITY MAPPING

A plain OAuth2 provider - one with C<identity_endpoint> rather than
C<oidc> - returns whatever shape its user API happens to use, so the
provider needs a way to turn that into the normalized identity the
rest of Punk::OAuth2 expects. That is C<identity_map>: a coderef called
with the decoded identity response and the decoded emails response
(C<undef> when there is no C<emails_endpoint>, or it did not answer
200), returning a hashref that is merged into the identity.

	identity_map => sub {
		my ($user, $emails) = @_;
		return { sub => $user->{uid}, email => $user->{mail} };
	},

The github preset points this at C<Punk::OAuth2::_github_identity>, an
XSUB that produces:

=over 4

=item C<sub>

C<< $user->{id} >>, stringified. GitHub sends it as a number, and an
identity that changes type between JSON decoders is a subtle way to
lose a session.

=item C<email>

The primary address from the emails response, or the first one it
lists if none is flagged primary, falling back to C<< $user->{email} >>
when the emails endpoint gave nothing.

=item C<email_verified>

The C<verified> flag belonging to whichever address was chosen, or
C<undef> if the response did not say.

=item C<name>

C<< $user->{name} >>, falling back to C<< $user->{login} >> - the
display name is optional on GitHub and frequently unset.

=item C<picture>

C<< $user->{avatar_url} >>.

=back

With no C<identity_map>, the provider falls back to reading C<sub> (or
C<id>), C<email> and C<name> straight off the identity response. Either
way the untouched payload is always available as C<raw>, so a mapping
that drops a field costs you nothing.

=head1 SEE ALSO

L<Punk::Plugin::OAuth2> for the C<oauth2> declaration these presets are
used from, and L<Punk::OAuth2::Provider> for endpoint resolution,
discovery and the full set of provider fields.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
