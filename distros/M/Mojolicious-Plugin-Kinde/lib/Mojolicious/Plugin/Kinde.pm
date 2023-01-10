package Mojolicious::Plugin::Kinde;
# ABSTRACT: A Mojo helper and route condition to extract Kinde auth header, verify JWT token, and return the claims
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::UserAgent;
use Mojo::JWT;
use Mojo::Exception;

our $VERSION = 'v0.0.2';

has jwt      => undef;
has iss      => '';
has audience => '';

sub register {
	my ( $self, $app, $conf ) = @_;

	my $jwks_url  = $conf->{jwks_url} || $app->config->{kinde}->{jwks_url};
	my $jwks_keys = Mojo::UserAgent->new->get($jwks_url)->result->json('/keys');
	$self->jwt( Mojo::JWT->new( jwks => $jwks_keys ) );

	$self->iss( $conf->{iss}           || $app->config->{kinde}->{iss} );
	$self->audience( $conf->{audience} || $app->config->{kinde}->{audience} );

	$app->helper( get_kinde_claims => sub { _validate_auth_header( $self, @_ ) } );

	$app->routes->add_condition( kinde_auth => sub { _validate_route( $self, @_ ) } );

} ## end sub register

sub _validate {
	my ( $self, $c, $token ) = @_;

	if ($token) {
		my $token_data = $token ? $self->jwt->decode($token) : undef;

		Mojo::Exception->throw('The token does not exist or is not valid') unless $token_data;
		Mojo::Exception->throw('The `iss` claim does not match')           unless $token_data->{iss} eq $self->iss;
		Mojo::Exception->throw('The signature `alg` is not RS256')         unless $self->jwt->algorithm eq 'RS256';
		Mojo::Exception->throw('The expected audience is missing')
		  if $self->audience
		  && ( scalar grep { $_ eq $self->audience } @{ $token_data->{aud} } ) == 0;

		$c->stash->{kinde_user} = { id => $token_data->{'sub'} };

		return $token_data;

	} else {

		return undef;

	} ## end if ($token)

} ## end sub _validate

sub _validate_auth_header {
	my ( $self, $c ) = @_;

	my $headers = $c->req->headers;
	my $auth    = $headers->header('Authorization');
	my $token   = $auth ? ( split( ' ', $auth ) )[1] : undef;

	return $self->_validate( $c, $token );

} ## end sub _validate_auth_header

sub _validate_route {
	my ( $self, $route, $c, $captures, $arg ) = @_;

	my $headers = $c->req->headers;
	my $auth    = $headers->header('Authorization');
	my $token   = $auth ? ( split( ' ', $auth ) )[1] : undef;

	return $self->_validate( $c, $token ) ? 1 : 0;

} ## end sub _validate_route


1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Kinde - A Mojo helper and route condition to extract Kinde auth header, verify JWT token, and return the claims

=head1 VERSION

version v0.0.1

=head1 SYNOPSIS

  package MyApp;
  use Mojo::Base 'Mojolicious';

  sub startup {
	  my $self = shift;

	  $self->plugin( 'Mojolicious::Plugin::Kinde' ); # config can also be supplied here

	  $self->routes->get('/api')->requires( kinde_auth => {} );

  }
  
  ...
  
  # myapp_mojo.pl (config)

  {
	  kinde => {
		  jwks_url => 'https://your-domain.kinde.com/.well-known/jwks.json',
		  iss      => 'https://your-domain.kinde.com',
	  },
  }
  
  ...
  
  my $claims = $c->get_kinde_claims

=head1 DESCRIPTION

Mojolicious::Plugin::Kinde creates a helper method and a route condition. Both retrieve the JWT 
token from the C<Authorization> header, verify the JWT, and do some sanity checks on the claims. 
The C<get_kinde_claims> helper will return the claims extracted from the token.

The sanity checks include:

=over 4

=item confirm C<iss> claim matches the value from C<kinde> config

=item confirm the C<alg> is C<RS256>

=item confirm the C<aud> array contains the value from C<kinde> config (if not empty)

=back 

=head1 HELPERS

=head2 get_kinde_claims()

Verifies the JWT from C<Authorization> header and returns the extracted claims.

=head1 ROUTE CONDITIONS

=head2 kinde_auth

Verifies the JWT from C<Authorization> header and returns boolean for the route condition.

=head1 METHODS

Mojolicious::Plugin::Kinde inherits all methods from Mojolicious::Plugin and implements the following new ones.

=head2 register

    $plugin->register(Mojolicious->new);

Register conditions in Mojolicious application.

=head1 SEE ALSO

=over 4

=item L<Mojo::JWT>

=item L<Kinde|https://kinde.com/> fantastic auth service

=back 

=head1 SUPPORT
 
=head2 Bugs / Feature Requests
 
Please report any bugs or feature requests through the issue tracker at
https://github.com/cngarrison/Mojolicious-Plugin-Kinde/issues. You will
be notified automatically of any progress on your issue.
 
=head2 Source Code
 
This is open source software. The code repository is available for
public review and contribution under the terms of the license.

https://github.com/cngarrison/Mojolicious-Plugin-Kinde

    git clone git://github.com/cngarrison/Mojolicious-Plugin-Kinde.git

=head1 AUTHOR

Charlie Garrison <cng@cngarrison.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Charlie Garrison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

DEBUG-
Value of c->get_kinde_claims is: {
    aud   [],
    azp   "fd4e006288c4e4cccc1f52e3408b581b",
    exp   1669721459,
    iat   1669635058,
    iss   "https://your-domain.au.kinde.com",
    jti   "e0db8424-84ee-44ea-b66c-762718354779",
    scp   [
        [0] "openid",
        [1] "profile",
        [2] "email",
        [3] "offline"
    ],
    sub   "kp:6e563cadc7d5d0cf10a7ef319d0f2ee7"
}
