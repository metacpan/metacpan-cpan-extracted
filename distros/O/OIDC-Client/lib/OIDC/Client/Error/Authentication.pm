package OIDC::Client::Error::Authentication;
use utf8;
use Moose;
extends 'OIDC::Client::Error';
use namespace::autoclean;

=encoding utf8

=head1 NAME

OIDC::Client::Error::Authentication

=head1 DESCRIPTION

Error class for an authentication problem.

=cut

has '+message' => (
  default => 'OIDC: authentication problem',
);

__PACKAGE__->meta->make_immutable;

1;
