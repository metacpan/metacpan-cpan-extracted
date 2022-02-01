package Sentry::Tracing::Transaction;
use Mojo::Base 'Sentry::Tracing::Span', -signatures;

# https://develop.sentry.dev/sdk/unified-api/tracing

use Mojo::Util 'dumper';

has _hub        => undef;
has sampled     => undef;
has context     => undef;
has name        => '<unlabeled transaction>';
has spans       => sub { [] };
has transaction => sub ($self) {$self};

sub finish ($self) {
  $self->SUPER::finish();

  return unless $self->sampled;

  my %transaction = (
    contexts        => { trace => $self->get_trace_context(), },
    spans           => $self->spans,
    start_timestamp => $self->start_timestamp,
    tags            => $self->tags,
    timestamp       => $self->timestamp,
    transaction     => $self->name,
    request         => $self->request,
    type            => 'transaction',
  );

  $self->_hub->capture_event(\%transaction);
}

sub set_name ($self, $name) {
  $self->name($name);
}

1;
