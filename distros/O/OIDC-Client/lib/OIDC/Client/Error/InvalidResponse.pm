package OIDC::Client::Error::InvalidResponse;
use utf8;
use Moose;
extends 'OIDC::Client::Error';
use namespace::autoclean;

=encoding utf8

=head1 NAME

OIDC::Client::Error::InvalidResponse

=head1 DESCRIPTION

Error class for an invalid response problem.

=cut

has '+message' => (
  default => 'OIDC: invalid response',
);

__PACKAGE__->meta->make_immutable;

1;
