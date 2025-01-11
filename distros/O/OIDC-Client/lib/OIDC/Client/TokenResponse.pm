package OIDC::Client::TokenResponse;
use utf8;
use Moose;
use namespace::autoclean;

has 'access_token' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'id_token' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'token_type' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'expires_in' => (
  is       => 'ro',
  isa      => 'Maybe[Int]',
  required => 0,
);

has 'refresh_token' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

has 'scope' => (
  is       => 'ro',
  isa      => 'Maybe[Str]',
  required => 0,
);

=encoding utf8

=head1 NAME

OIDC::Client::TokenResponse - OIDC token response

=head1 DESCRIPTION

Class representing an OIDC token response from provider

=head1 ATTRIBUTES

=head2 access_token

The access token issued by the provider

=head2 id_token

The identity token issued by the provider

=head2 token_type

The type of the access token

=head2 expires_in

The lifetime in seconds of the access token

=head2 refresh_token

The refresh token which can be used to obtain new access tokens
using the same authorization grant

=head2 scope

The scope of the access token

=cut

__PACKAGE__->meta->make_immutable;

1;
