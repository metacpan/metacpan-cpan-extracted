package Sentry::Tracing::Span;
use Mojo::Base -base, -signatures;

use HTTP::Status qw(status_message);
use Readonly;
use Sentry::Tracing::Status;
use Sentry::Tracing::Transaction;
use Sentry::Util qw(uuid4);
use Time::HiRes qw(time);

Readonly my $SPAN_ID_LENGTH => 16;

# https://develop.sentry.dev/sdk/unified-api/tracing

# Hexadecimal string representing a uuid4 value. The length is exactly 32
# characters. Dashes are not allowed. Has to be lowercase
has span_id => sub { substr(uuid4(), 0, $SPAN_ID_LENGTH) };

# Optional. A map or list of tags for this event. Each tag must be less than 200
# characters.
has tags => sub { {} };

# Required. Determines which trace the Span belongs to. The value should be 16
# random bytes encoded as a hex string (32 characters long).
has trace_id => sub { uuid4() };

# Recommended. Short code identifying the type of operation the span is
# measuring.
has op => undef;

# Optional. Longer description of the span's operation, which uniquely
# identifies the span but is consistent across instances of the span.
has description => undef;

# Required. A timestamp representing when the measuring started. The format is
# either a string as defined in RFC 3339 or a numeric (integer or float) value
# representing the number of seconds that have elapsed since the Unix epoch. The
# start_timestamp value must be greater or equal the timestamp value, otherwise
# the Span is discarded as invalid.
has start_timestamp => time;

# Required. A timestamp representing when the measuring finished. The format is
# either a string as defined in RFC 3339 or a numeric (integer or float) value
# representing the number of seconds that have elapsed since the Unix epoch.
has timestamp => undef;

# Optional. Describes the status of the Span/Transaction.
has status => undef;

# Optional. Arbitrary data associated with this Span.
has data => undef;

has parent_span_id => undef;

# Was this span chosen to be sent as part of the sample?
has sampled => undef;

has spans       => sub { [] };
has transaction => undef;
has request     => undef;

sub start_child ($self, $span_context = {}) {
  my $child_span = Sentry::Tracing::Span->new({
    $span_context->%*,
    parent_span_id  => $self->span_id,
    sampled         => $self->sampled,
    trace_id        => $self->trace_id,
    start_timestamp => time,
  });

  push $self->spans->@*, $child_span;

  $child_span->transaction($self->transaction);

  return $child_span;
}

sub get_trace_context ($self) {
  return {
    data           => $self->data,
    description    => $self->description,
    op             => $self->op,
    parent_span_id => $self->parent_span_id,
    span_id        => $self->span_id,
    status         => $self->status,
    tags           => $self->tags,
    trace_id       => $self->trace_id,
  };
}

sub TO_JSON ($self) {
  return {
    data            => $self->data,
    description     => $self->description,
    op              => $self->op,
    parent_span_id  => $self->parent_span_id,
    span_id         => $self->span_id,
    start_timestamp => $self->start_timestamp,
    status          => $self->status,
    tags            => $self->tags,
    timestamp       => $self->timestamp,
    trace_id        => $self->trace_id,
  };
}

sub set_tag ($self, $key, $value) {
  $self->tags({ $self->tags->%*, $key => $value });
}

sub set_http_status ($self, $status) {
  $self->set_tag('http.status_code' => $status);
  $self->status(Sentry::Tracing::Status->from_http_code($status));
}

sub to_hash ($self) {
  return { 'sentry-trace' => $self->to_sentry_trace };
}

sub finish ($self) {
  $self->timestamp(time);
}

1;
