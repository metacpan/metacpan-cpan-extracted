package OIDC::Client::TokenResponseParser;
use utf8;
use Moose;
extends 'OIDC::Client::ResponseParser';
use namespace::autoclean;

use OIDC::Client::TokenResponse;

=encoding utf8

=head1 NAME

OIDC::Client::TokenResponseParser - Token endpoint response parser

=head1 DESCRIPTION

Token endpoint response parser.

L<OIDC::Client::ResponseParser> subclass.

=head1 METHODS

=head2 parse( $response )

Overrides the parent method to return an L<OIDC::Client::TokenResponse> object.

=cut

around 'parse' => sub {
  my $orig = shift;
  my $self = shift;

  my $result = $self->$orig(@_);

  return OIDC::Client::TokenResponse->new($result);
};

__PACKAGE__->meta->make_immutable;

1;
