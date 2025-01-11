package OIDC::Client::Error::Provider;
use utf8;
use Moose;
extends 'OIDC::Client::Error';
use namespace::autoclean;

=encoding utf8

=head1 NAME

OIDC::Client::Error::Provider

=head1 DESCRIPTION

Error class for a problem returned by the provider.

=cut

has '+message' => (
  builder => '_build_message',
  lazy    => 1,
);

has 'response_parameters' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

has 'alternative_error' => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);

sub _build_message {
  my $self = shift;

  my $params = $self->{response_parameters};

  my $message = $params->{error}
                  || $self->alternative_error
                  || 'OIDC: problem returned by the provider';

  if (my @description_keys = sort grep { $_ ne 'error' } keys %$params) {
    $message .= ' (' . join(', ', map { "$_: $params->{$_}" } @description_keys) . ')';
  }

  return $message;
}

__PACKAGE__->meta->make_immutable;

1;
