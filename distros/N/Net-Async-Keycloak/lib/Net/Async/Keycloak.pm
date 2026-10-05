package Net::Async::Keycloak;

# ABSTRACT: Async Perl client for Keycloak identity management (IO::Async + Future)

use Moo;
extends 'IO::Async::Notifier';
use Net::Async::HTTP;
use Net::Async::Keycloak::Admin;
use Net::Async::Keycloak::Auth;
use Net::Async::Keycloak::Error;
use Net::Async::Keycloak::Error::API;
use Net::Async::Keycloak::Error::Network;
use Net::Async::Keycloak::Error::Validation;
use Net::Async::Keycloak::OIDC;
use Types::Standard qw( InstanceOf Object Str );
use URI::Escape qw( uri_escape_utf8 );

our $VERSION = '0.001';


# IO::Async::Notifier->new hands every constructor key to configure(), which
# croaks on keys it does not know. Keep ours away from it.
sub FOREIGNBUILDARGS {
  my ( $class, @args ) = @_;
  my %arg = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  delete @arg{qw( base_url realm username password client_id client_secret token auth_realm http auth )};
  return %arg;
}

has base_url => ( is => 'ro', isa => Str, required => 1 );
has realm    => ( is => 'ro', isa => Str, required => 1 );


has username      => ( is => 'ro', isa => Str, predicate => 'has_username' );
has password      => ( is => 'ro', isa => Str );
has client_id     => ( is => 'ro', isa => Str, predicate => 'has_client_id' );
has client_secret => ( is => 'ro', isa => Str );
has token         => ( is => 'ro', isa => Str, predicate => 'has_token' );


has auth_realm => ( is => 'lazy', isa => Str );

sub _build_auth_realm { $_[0]->has_username ? 'master' : $_[0]->realm }


has http => ( is => 'lazy', isa => Object, predicate => 'has_http' );

sub _build_http {
  my ( $self ) = @_;
  # no redirects: nothing here needs one, and none may carry the admin token elsewhere
  my $http = Net::Async::HTTP->new( user_agent => 'Net-Async-Keycloak/'.$VERSION, max_redirects => 0, timeout => 30, fail_on_error => 0 );
  $self->add_child($http);
  return $http;
}


has auth => ( is => 'lazy', isa => InstanceOf['Net::Async::Keycloak::Auth'] | Types::Standard::Undef );

sub _build_auth {
  my ( $self ) = @_;
  return Net::Async::Keycloak::Auth->new( http => $self->http, token => $self->token ) if $self->has_token;
  return unless $self->has_username || $self->has_client_id;
  return Net::Async::Keycloak::Auth->new(
    http           => $self->http,
    token_endpoint => $self->base_url.'/realms/'.uri_escape_utf8( $self->auth_realm ).'/protocol/openid-connect/token',
    map { $_ => $self->$_ } grep { defined $self->$_ } qw( username password client_id client_secret )
  );
}


has oidc => ( is => 'lazy', init_arg => undef );

sub _build_oidc { Net::Async::Keycloak::OIDC->new( issuer => $_[0]->issuer, http => $_[0]->http ) }


has admin => ( is => 'lazy', init_arg => undef );

sub _build_admin {
  my ( $self ) = @_;
  return Net::Async::Keycloak::Admin->new(
    base_url => $self->base_url,
    realm    => $self->realm,
    http     => $self->http,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}


# The parent is not a Moo class, so there is no BUILDARGS to wrap.
sub BUILDARGS {
  my ( $class, @args ) = @_;
  my %args = @args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args;
  $args{base_url} =~ s{/+\z}{} if defined $args{base_url};
  return \%args;
}

sub BUILD {
  my ( $self ) = @_;
  for (qw( base_url realm )) {
    Net::Async::Keycloak::Error::Validation->throw( message => __PACKAGE__.' needs a '.$_ ) unless length $self->$_;
  }
  return;
}

sub issuer { $_[0]->base_url.'/realms/'.uri_escape_utf8( $_[0]->realm ) }


sub for_realm {
  my ( $self, $realm ) = @_;
  return ref($self)->new(
    base_url   => $self->base_url,
    realm      => $realm,
    http       => $self->http,
    auth_realm => $self->auth_realm,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Keycloak - Async Perl client for Keycloak identity management (IO::Async + Future)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Future::AsyncAwait;
    use Net::Async::Keycloak;

    my $loop = IO::Async::Loop->new;
    my $kc   = Net::Async::Keycloak->new(
      base_url => 'https://id.example.org',
      realm    => 'main',
      username => 'admin',
      password => $ENV{KEYCLOAK_ADMIN_PASSWORD},
    );
    $loop->add($kc);

    my $claims = await $kc->oidc->verify_token_f( $jwt, audience => 'my-api', type => 'Bearer' );
    my $r      = await $kc->admin->ensure_client_f( clientId => 'my-cli', publicClient => \1 );

=head1 DESCRIPTION

The asynchronous twin of L<WWW::Keycloak>, on L<IO::Async> and L<Future>: the
same facade, the same parts, every method with C<_f> returning a future.
Requests are built and responses read by the same code as in the sync client,
and the C<ensure_*_f> methods compare with the same L<WWW::Keycloak::Diff>, so
both clients do the same thing to a realm.

Add the object to a loop before the first request: the L<Net::Async::HTTP> it
sends through is its child notifier.

=head2 base_url

=head2 realm

Required, as in L<WWW::Keycloak>. A trailing slash on C<base_url> is removed.

=head2 username

=head2 password

=head2 client_id

=head2 client_secret

=head2 token

The admin login, as in L<WWW::Keycloak>.

=head2 auth_realm

As in L<WWW::Keycloak>.

=head2 http

The L<Net::Async::HTTP> every part shares, built as a child of this notifier.
Pass one in to share it; it is then not added as a child.

=head2 auth

The L<Net::Async::Keycloak::Auth>, or undef without admin login.

=head2 oidc

The L<Net::Async::Keycloak::OIDC> of this realm.

=head2 admin

The L<Net::Async::Keycloak::Admin> of this realm.

=head2 issuer

=head2 for_realm

    my $dev = $kc->for_realm('dev');

The same client for another realm, sharing the L<Net::Async::HTTP> and the
admin login. The new object is not a notifier of its own in any loop; it sends
through the shared C<http>.

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
