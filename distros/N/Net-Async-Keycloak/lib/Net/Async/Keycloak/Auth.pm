package Net::Async::Keycloak::Auth;

# ABSTRACT: Get and keep a valid admin token for the Keycloak Admin API, asynchronously

use Moo;
with 'Net::Async::Keycloak::Role::HTTP';
with 'WWW::Keycloak::Role::HTTP';
use Future;
use Future::AsyncAwait;
use Scalar::Util qw( blessed );
use Types::Standard qw( CodeRef Int Object Str );
use namespace::autoclean;

our $VERSION = '0.001';


has http => (
  is       => 'ro',
  isa      => Object,
  required => 1
);


has token_endpoint => ( is => 'ro', isa => Str );
has username       => ( is => 'ro', isa => Str, predicate => 'has_username' );
has password       => ( is => 'ro', isa => Str );
has client_id      => ( is => 'ro', isa => Str, predicate => 'has_client_id' );
has client_secret  => ( is => 'ro', isa => Str );
has fixed_token    => ( is => 'ro', isa => Str, init_arg => 'token', predicate => 'has_fixed_token' );


has margin => ( is => 'ro', isa => Int, default => 30 );
has now    => ( is => 'ro', isa => CodeRef, default => sub { sub { time } } );


has _access          => ( is => 'rw' );
has _access_expires  => ( is => 'rw' );
has _refresh         => ( is => 'rw' );
has _refresh_expires => ( is => 'rw' );
has _pending         => ( is => 'rw' );

sub BUILD {
  my ( $self ) = @_;
  return if $self->has_fixed_token;
  $self->validation_error_class->throw( message => __PACKAGE__.' needs username and password, client_id and client_secret, or token' )
    unless ( $self->has_username && defined $self->password ) || ( $self->has_client_id && defined $self->client_secret );
  $self->validation_error_class->throw( message => __PACKAGE__.' needs a token_endpoint' )
    unless defined $self->token_endpoint && length $self->token_endpoint;
  return;
}

sub renewable { $_[0]->has_fixed_token ? 0 : 1 }

sub token_f {
  my ( $self ) = @_;
  return Future->done( $self->fixed_token ) if $self->has_fixed_token;
  return Future->done( $self->_access )
    if defined $self->_access && $self->now->() < $self->_access_expires - $self->margin;
  unless ( $self->_pending ) {
    my $login = $self->_renew_f->on_ready( sub { $self->_pending(undef) } );
    return $login if $login->is_ready;
    $self->_pending($login);
  }
  # every caller gets its own view: cancelling one must not cancel the login
  # the others are waiting for
  return $self->_pending->without_cancel;
}


sub invalidate {
  my ( $self, $refused ) = @_;
  # a refusal of a token that was already replaced says nothing about the new one
  return if defined $refused && ( $self->_access // '' ) ne $refused;
  $self->_access(undef);
  $self->_refresh(undef);
  return;
}


async sub _renew_f {
  my ( $self ) = @_;
  if ( defined $self->_refresh && $self->now->() < $self->_refresh_expires - $self->margin ) {
    my $renewed = eval {
      await $self->_grant_f( { grant_type => 'refresh_token', refresh_token => $self->_refresh, $self->_client } );
      1;
    };
    return $self->_access if $renewed;
  }
  await $self->_grant_f( $self->has_username
    ? { grant_type => 'password', username => $self->username, password => $self->password, $self->_client }
    : { grant_type => 'client_credentials', $self->_client } );
  return $self->_access;
}

sub _client {
  my ( $self ) = @_;
  return (
    client_id => $self->has_client_id ? $self->client_id : 'admin-cli',
    defined $self->client_secret ? ( client_secret => $self->client_secret ) : ()
  );
}

async sub _grant_f {
  my ( $self, $form ) = @_;
  my $now  = $self->now->();
  my $data = eval { ( await $self->send_request_f( POST => $self->token_endpoint, form => $form ) )->{data} };
  if ( my $error = $@ ) {
    die $error unless blessed $error && $error->isa('WWW::Keycloak::Error::API');
    $self->api_error_class->throw(
      message     => 'admin login failed: '.$error->http_status.( defined $error->api_message ? ' - '.$error->api_message : '' ),
      http_status => $error->http_status,
      api_message => $error->api_message,
      oauth_error => $error->oauth_error
    );
  }
  $self->_access( $data->{access_token} );
  $self->_access_expires( $now + ( $data->{expires_in} || 60 ) );
  $self->_refresh( $data->{refresh_token} );
  $self->_refresh_expires( $now + ( $data->{refresh_expires_in} || 0 ) );
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Keycloak::Auth - Get and keep a valid admin token for the Keycloak Admin API, asynchronously

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $auth = Net::Async::Keycloak::Auth->new(
      http           => $http,
      token_endpoint => 'https://id.example.org/realms/master/protocol/openid-connect/token',
      username       => 'admin',
      password       => $password,
    );
    my $bearer = await $auth->token_f;

=head1 DESCRIPTION

The asynchronous L<WWW::Keycloak::Auth>: same login options, same renewal
rules, futures instead of values. Callers asking for a token while a login is
under way share that login instead of starting their own.

=head2 http

Required. The L<Net::Async::HTTP> to use.

=head2 token_endpoint

=head2 username

=head2 password

=head2 client_id

=head2 client_secret

=head2 token

As in L<WWW::Keycloak::Auth>.

=head2 margin

=head2 now

As in L<WWW::Keycloak::Auth>.

=head2 token_f

    my $bearer = await $auth->token_f;

A future of a token that is valid for at least C<margin> more seconds.

=head2 invalidate

    $auth->invalidate($refused_token);

As in L<WWW::Keycloak::Auth>. Given the token that was refused, it forgets the
current token only if that is still the one; requests that were refused
together then cause one new login, not one each.

=head2 renewable

As in L<WWW::Keycloak::Auth>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-keycloak/issues>.

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
