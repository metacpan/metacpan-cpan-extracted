package OIDC::Client::Error;
use utf8;
use Moose;
extends 'Throwable::Error';
use namespace::autoclean;

=encoding utf8

=head1 NAME

OIDC::Client::Error

=head1 DESCRIPTION

Library error parent class.

=cut

__PACKAGE__->meta->make_immutable;

1;
