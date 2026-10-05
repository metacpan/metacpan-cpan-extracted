package Net::Async::Authentik::OIDC;

# ABSTRACT: OpenID Connect against one authentik application, asynchronously

use Moo;
with 'Net::Async::Authentik::Role::HTTP';
with 'WWW::Authentik::Role::HTTP';
use Crypt::JWT qw( decode_jwt );
use Future;
use Future::AsyncAwait;
use Types::Standard qw( ArrayRef CodeRef Int Object Str );
use URI;
use namespace::autoclean;

our $VERSION = '0.001';


has application_url => ( is => 'ro', isa => Str | Types::Standard::Undef );


has http => ( is => 'ro', isa => Object, required => 1 );


has client_id => ( is => 'ro', isa => Str, predicate => 'has_client_id' );


has algorithms => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [qw( RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 )] }
);
has jwks_min_age => ( is => 'ro', isa => Int, default => 60 );
has now          => ( is => 'ro', isa => CodeRef, default => sub { sub { time } } );


has _discovery    => ( is => 'rw', init_arg => undef );
has _jwks         => ( is => 'rw', init_arg => undef );
has _jwks_fetched => ( is => 'rw', init_arg => undef );
has _in_flight    => ( is => 'ro', init_arg => undef, default => sub { {} } );

# One fetch for everybody who asks while it is under way, each with a view of
# its own so that cancelling one does not cancel the fetch.
sub _shared {
  my ( $self, $key, $start ) = @_;
  my $in_flight = $self->_in_flight;
  unless ( $in_flight->{$key} ) {
    my $future = $start->()->on_ready( sub { delete $in_flight->{$key} } );
    return $future if $future->is_ready;
    $in_flight->{$key} = $future;
  }
  return $in_flight->{$key}->without_cancel;
}

sub _url {
  my ( $self ) = @_;
  return $self->application_url if defined $self->application_url && length $self->application_url;
  return;
}

sub discovery_f {
  my ( $self ) = @_;
  return $self->fail_validation( __PACKAGE__.' needs an application slug' ) unless $self->_url;
  return Future->done( $self->_discovery ) if $self->_discovery;
  return $self->_shared( discovery => sub { $self->_fetch_discovery_f } );
}

async sub _fetch_discovery_f {
  my ( $self ) = @_;
  my $data = ( await $self->send_request_f( GET => $self->_url.'/.well-known/openid-configuration' ) )->{data};
  die $self->validation_error_class->new( message => 'discovery for '.$self->_url.' returned no JSON object' )
    unless ref $data eq 'HASH';
  return $self->_discovery($data);
}


async sub endpoint_f {
  my ( $self, $name ) = @_;
  my $url = ( await $self->discovery_f )->{$name};
  die $self->validation_error_class->new( message => 'the discovery document of '.$self->_url.' has no '.$name )
    unless defined $url;
  return $url;
}


sub issuer_f                 { $_[0]->endpoint_f('issuer') }
sub authorization_endpoint_f { $_[0]->endpoint_f('authorization_endpoint') }
sub token_endpoint_f         { $_[0]->endpoint_f('token_endpoint') }
sub userinfo_endpoint_f      { $_[0]->endpoint_f('userinfo_endpoint') }
sub introspection_endpoint_f { $_[0]->endpoint_f('introspection_endpoint') }
sub revocation_endpoint_f    { $_[0]->endpoint_f('revocation_endpoint') }
sub end_session_endpoint_f   { $_[0]->endpoint_f('end_session_endpoint') }
sub device_endpoint_f        { $_[0]->endpoint_f('device_authorization_endpoint') }
sub jwks_uri_f               { $_[0]->endpoint_f('jwks_uri') }


sub jwks_f {
  my ( $self, %opt ) = @_;
  return $self->fail_validation( __PACKAGE__.' needs an application slug' ) unless $self->_url;
  return Future->done( $self->_jwks ) if $self->_jwks && !$opt{force_refresh};
  return $self->_shared( jwks => sub {
    # counted from the start, so that verifications already under way see it
    $self->_jwks_fetched( $self->now->() );
    $self->_fetch_jwks_f;
  } );
}

async sub _fetch_jwks_f {
  my ( $self ) = @_;
  my $uri  = await $self->jwks_uri_f;
  my $data = ( await $self->send_request_f( GET => $uri ) )->{data};
  # without this the cache stays empty and every verification fetches again,
  # which is what the sibling above already guards against
  die $self->validation_error_class->new( message => 'the keys of '.$self->_url.' came back as no JSON object' )
    unless ref $data eq 'HASH';
  return $self->_jwks($data);
}


async sub issuer_names_the_application_f {
  my ( $self ) = @_;
  return ( await $self->issuer_f ) eq $self->_url.'/' ? 1 : 0;
}


async sub verify_token_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 2, @_ );
  return await $_[0]->fail_validation('verify_token_f: the arguments after the first 1 do not make pairs') unless $ok;
  my ( $self, $token ) = @_;
  my %opt = %$pairs;
  die $self->validation_error_class->new( message => 'verify_token needs a token' )
    unless defined $token && length $token;
  die $self->validation_error_class->new( message => "verify_token: type must be 'access' or 'id'" )
    if defined $opt{type} && $opt{type} ne 'access' && $opt{type} ne 'id';
  my $audience = exists $opt{audience} ? $opt{audience}
    : $self->has_client_id            ? $self->client_id
    :                                   undef;
  my $issuer = await $self->issuer_f;
  # Every provider of one authentik signs with the same key, so the issuer is
  # all that separates two applications - and with issuer_mode: global it is
  # the bare instance URL, the same for all of them. Then only the audience
  # tells them apart, and verifying without one would accept any token the
  # instance ever issued.
  die $self->validation_error_class->new( message => 'verify_token cannot tell this application apart: '
    .'the provider issues tokens as "'.$issuer.'", which does not name the application, so a token '
    .'of any other application of this authentik would pass. Give an audience, set client_id on the client, '
    .'or say any_audience => 1 if you really mean to accept them all.' )
    if !defined $audience && !$opt{any_audience} && !await( $self->issuer_names_the_application_f );
  my %check = (
    token          => $token,
    verify_iss     => $issuer,
    verify_exp     => 1,
    accepted_alg   => $self->algorithms,
    decode_payload => 1,
    defined $audience ? ( verify_aud => $audience ) : ()
  );
  my $keys   = await $self->jwks_f;
  my $claims = eval { decode_jwt( %check, kid_keys => $keys ) };
  my $error  = $@;
  # a key authentik rotated in since the keys were fetched: fetch them again,
  # but only for that reason, and not more often than jwks_min_age allows. A
  # fetch already under way counts, or twenty concurrent verifications would
  # each want their own.
  my $again = $self->_in_flight->{jwks} || $self->now->() - ( $self->_jwks_fetched // 0 ) >= $self->jwks_min_age;
  if ( !$claims && $error =~ /kid_keys lookup failed/ && $again ) {
    $keys   = await $self->jwks_f( force_refresh => 1 );
    $claims = eval { decode_jwt( %check, kid_keys => $keys ) };
    $error  = $@;
  }
  $self->_reject( $error =~ s/ at \S+ line \d+.*//sr ) unless $claims;
  if ( defined $opt{type} ) {
    my $looks_like_access = exists $claims->{scope} ? 1 : 0;
    $self->_reject('not an access token: it carries no scope claim')
      if $opt{type} eq 'access' && !$looks_like_access;
    $self->_reject('not an ID token: it carries a scope claim')
      if $opt{type} eq 'id' && $looks_like_access;
  }
  return $claims;
}

sub _reject {
  my ( $self, $why ) = @_;
  die $self->validation_error_class->new( message => 'token rejected: '.$why );
}


async sub userinfo_f {
  my ( $self, $access_token ) = @_;
  die $self->validation_error_class->new( message => 'userinfo needs an access token' )
    unless defined $access_token && length $access_token;
  my $endpoint = await $self->userinfo_endpoint_f;
  return ( await $self->send_request_f( GET => $endpoint, bearer => $access_token ) )->{data};
}

async sub introspect_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 2, @_ );
  return await $_[0]->fail_validation('introspect_f: the arguments after the first 1 do not make pairs') unless $ok;
  my ( $self, $token ) = @_;
  my %client = %$pairs;
  return await $self->_token_call_f( await( $self->introspection_endpoint_f ),
    { token => $token, defined $client{token_type_hint} ? ( token_type_hint => $client{token_type_hint} ) : () }, %client );
}

async sub revoke_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 2, @_ );
  return await $_[0]->fail_validation('revoke_f: the arguments after the first 1 do not make pairs') unless $ok;
  my ( $self, $token ) = @_;
  my %client = %$pairs;
  await $self->_token_call_f( await( $self->revocation_endpoint_f ),
    { token => $token, defined $client{token_type_hint} ? ( token_type_hint => $client{token_type_hint} ) : () }, %client );
  return 1;
}

sub client_credentials_token_f    { my ( $self, %arg ) = @_; $self->_grant_f( client_credentials => [qw( scope username password )], %arg ) }
sub refresh_token_f               { my ( $self, $refresh, %arg ) = @_; $self->_grant_f( refresh_token => [qw( refresh_token scope )], %arg, refresh_token => $refresh ) }
sub exchange_authorization_code_f { my ( $self, %arg ) = @_; $self->_grant_f( authorization_code => [qw( code redirect_uri code_verifier )], %arg ) }
sub device_token_f                { my ( $self, %arg ) = @_; $self->_grant_f( 'urn:ietf:params:oauth:grant-type:device_code' => ['device_code'], %arg ) }

async sub device_authorization_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('device_authorization_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %arg = %$pairs;
  my $endpoint = await $self->device_endpoint_f;
  return await $self->_token_call_f( $endpoint,
    { defined $arg{scope} ? ( scope => $arg{scope} ) : () }, %arg );
}


async sub authorization_url_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('authorization_url_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %arg = %$pairs;
  die $self->validation_error_class->new( message => 'authorization_url needs a client_id' ) unless defined $arg{client_id};
  die $self->validation_error_class->new( message => 'authorization_url needs a redirect_uri' ) unless defined $arg{redirect_uri};
  my $uri = URI->new( await $self->authorization_endpoint_f );
  $uri->query_form(
    response_type => $arg{response_type} // 'code',
    map { $_ => $arg{$_} } grep { defined $arg{$_} }
      qw( client_id redirect_uri scope state nonce prompt max_age acr_values
          code_challenge code_challenge_method response_mode )
  );
  return $uri->as_string;
}


async sub _grant_f {
  my ( $self, $type, $fields, %arg ) = @_;
  return await $self->_token_call_f( await( $self->token_endpoint_f ),
    { grant_type => $type, map { $_ => $arg{$_} } grep { defined $arg{$_} } @$fields }, %arg );
}

async sub _token_call_f {
  my ( $self, $url, $form, %arg ) = @_;
  die $self->validation_error_class->new( message => 'a client_id is needed' ) unless defined $arg{client_id};
  my %form = (
    %$form,
    client_id => $arg{client_id},
    defined $arg{client_secret} ? ( client_secret => $arg{client_secret} ) : ()
  );
  return ( await $self->send_request_f( POST => $url, form => \%form ) )->{data} // {};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Authentik::OIDC - OpenID Connect against one authentik application, asynchronously

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $oidc   = $ak->oidc;
    my $claims = await $oidc->verify_token_f( $jwt, type => 'access' );
    my $tokens = await $oidc->client_credentials_token_f( client_id => $id, client_secret => $secret );

=head1 DESCRIPTION

The asynchronous L<WWW::Authentik::OIDC>: the same methods with C<_f> and
futures, the same rules, including when the keys are fetched again and what
C<type> can and cannot tell.

Two things are its own. Callers asking for the discovery document or the
signing keys while a fetch is under way B<share that one fetch> instead of
starting their own, and each gets a view that can be cancelled without taking
the fetch down with it. And nothing throws: every method returns a future,
and a wrong argument fails it.

=head2 application_url

C<< <base_url>/application/o/<slug> >>, without a trailing slash. Undef when
the facade was built without an application; every method then fails with a
validation error.

=head2 http

Required. The L<Net::Async::HTTP> to send through.

=head2 client_id

The client id of this application's provider. When it is set,
L</verify_token_f> checks it as the audience unless the caller names another
one.

=head2 algorithms

=head2 jwks_min_age

=head2 now

As in L<WWW::Authentik::OIDC>.

=head2 discovery_f

    my $document = await $oidc->discovery_f;

The discovery document, fetched once and kept. Callers asking while the fetch
is under way share it.

=head2 endpoint_f

    my $url = await $oidc->endpoint_f('device_authorization_endpoint');

A URL from the discovery document. Fails when it is missing.

=head2 issuer_f

What authentik puts into C<iss> and what L</verify_token_f> checks against.

=head2 authorization_endpoint_f

=head2 token_endpoint_f

=head2 userinfo_endpoint_f

=head2 introspection_endpoint_f

=head2 revocation_endpoint_f

=head2 end_session_endpoint_f

=head2 device_endpoint_f

=head2 jwks_uri_f

The endpoints out of the discovery document.

=head2 jwks_f

    my $keys = await $oidc->jwks_f;
    my $keys = await $oidc->jwks_f( force_refresh => 1 );

The application's public signing keys, kept after the first fetch. Callers
asking while a fetch is under way share it.

=head2 issuer_names_the_application_f

True when the issuer out of the discovery document is this application's own
address, which is what C<issuer_mode: per_provider> gives. False under
C<issuer_mode: global>, where every provider of the instance issues tokens
under the bare instance URL.

=head2 verify_token_f

    my $claims = await $oidc->verify_token_f( $jwt );
    my $claims = await $oidc->verify_token_f( $jwt, audience => $client_id, type => 'access' );

As L<WWW::Authentik::OIDC/verify_token>, returning a future. Checks
signature, issuer, expiry and audience.

B<The audience is what separates two applications of one authentik.> Every
provider of an instance signs with the same key, so the issuer is the only
other thing that could tell them apart — and with C<issuer_mode: global> the
issuer is the bare instance URL, the same for all of them. Verifying without
an audience on such an instance would accept any token it ever issued, so
this method refuses to: give C<audience>, set L</client_id> on the client, or
pass C<< any_audience => 1 >>.

C<type> is a B<heuristic>. authentik signs ID tokens and access tokens the
same way and puts no C<typ> into the JOSE header; the only reliable
difference is that an access token carries a C<scope> claim. Without C<type>
the kind of token is not checked.

=head2 userinfo_f

=head2 introspect_f

=head2 revoke_f

=head2 client_credentials_token_f

=head2 refresh_token_f

=head2 exchange_authorization_code_f

=head2 device_authorization_f

=head2 device_token_f

As the methods without C<_f> in L<WWW::Authentik::OIDC>, returning futures. A
device-flow poll before anyone has approved fails with an API error whose
C<oauth_error> is C<authorization_pending>.

=head2 authorization_url_f

    my $url = await $oidc->authorization_url_f( client_id => $id, redirect_uri => $uri, scope => 'openid' );

The address a browser is sent to. A future, because the endpoint comes out of
the discovery document.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
