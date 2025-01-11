package OIDC::Client::Error::TokenValidation;
use utf8;
use Moose;
extends 'OIDC::Client::Error';
use namespace::autoclean;

=encoding utf8

=head1 NAME

OIDC::Client::Error::TokenValidation

=head1 DESCRIPTION

Error class for a token validation problem.

=cut

has '+message' => (
  default => 'OIDC: token validation problem',
);

__PACKAGE__->meta->make_immutable;

1;
