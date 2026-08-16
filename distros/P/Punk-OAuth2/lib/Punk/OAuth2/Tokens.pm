package Punk::OAuth2::Tokens;

use 5.024;
use strict;
use warnings;

use Punk::OAuth2;

our $VERSION = '0.01';


1;

__END__

=head1 NAME

Punk::OAuth2::Tokens - a token-endpoint response

=head1 SYNOPSIS

	sub on_login {
		my ($c, $identity, $tokens) = @_;
		$tokens->access_token;    # the access token string
		$tokens->refresh_token;   # undef unless one was issued
		$tokens->id_claims;       # verified id_token claims (OIDC)
		return unless $tokens->expired;
	}

=head1 DESCRIPTION

The object handed to C<on_login> and returned by C<< $c->oauth2_refresh >>,
implemented in XS. C<expires_in> from the wire is converted to an
absolute C<expires_at> at construction.

=head1 CONSTRUCTORS

=head2 new

	my $tokens = Punk::OAuth2::Tokens->new(
		access_token  => $at,
		token_type    => 'Bearer',
		expires_in    => 3600,       # becomes expires_at = now + 3600
		refresh_token => $rt,
	);

=head2 from_response

	my $tokens = Punk::OAuth2::Tokens->from_response($decoded_json);

Builds a Tokens object from a decoded token-endpoint response hash,
keeping the original under L</raw>.

=head1 ACCESSORS

=head2 access_token

	my $at = $tokens->access_token;

=head2 token_type

	my $type = $tokens->token_type;   # 'Bearer'

=head2 refresh_token

	my $rt = $tokens->refresh_token;   # undef if none was issued

=head2 id_token

	my $jwt = $tokens->id_token;   # the raw OIDC id_token (OIDC only)

=head2 id_claims

	my $claims = $tokens->id_claims;   # verified id_token claims hashref
	my $sub    = $tokens->id_claims->{sub};

The claims of a verified OIDC id_token (set by the client flow after
verification). Also a setter: C<< $tokens->id_claims(\%claims) >>.

=head2 scope

	my $scope = $tokens->scope;   # the granted scope string, or undef

=head2 expires_at

	my $epoch = $tokens->expires_at;   # absolute expiry, or undef

=head2 raw

	my $hash = $tokens->raw;   # the decoded response, untouched

=head1 PREDICATES

=head2 expired

	$tokens->expired;        # true if within 30s of expiry (default)
	$tokens->expired(0);     # exact expiry, no leeway

True when the access token has expired (a leeway in seconds, default 30,
is subtracted so a token about to expire counts as expired).

=head2 refreshable

	if ($tokens->refreshable) {
		$tokens = $c->oauth2_refresh('google', $tokens);
	}

True when a refresh token is present.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
