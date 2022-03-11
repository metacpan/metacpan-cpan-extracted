package Sentry::Hub;
use Mojo::Base -base, -signatures;

use Mojo::Util 'dumper';
use Sentry::Hub::Scope;
use Sentry::Logger 'logger';
use Sentry::Severity;
use Sentry::Tracing::SamplingMethod;
use Sentry::Tracing::Transaction;
use Sentry::Util qw(uuid4);
use Time::HiRes qw(time);
use Try::Tiny;

my $Instance;

has _last_event_id => undef;
has _stack         => sub { [{}] };
has client         => undef;
has scopes         => sub { [Sentry::Hub::Scope->new] };

sub init ($package, $options) {
  $Instance = Sentry::Hub->new($options);
}

sub reset ($self) {
  $self->scopes([Sentry::Hub::Scope->new]);
}

sub bind_client ($self, $client) {
  $self->client($client);
  $client->setup_integrations();
}

sub get_current_scope ($package) {
  return @{ $package->get_current_hub()->scopes }[-1];
}

sub get_current_hub {
  $Instance //= Sentry::Hub->new();
  return $Instance;
}

sub configure_scope ($self, $cb) {
  $cb->($self->get_current_scope);
}

sub push_scope ($self) {
  my $scope = $self->get_current_scope->clone;
  push $self->scopes->@*, $scope;
  return $scope;
}
sub pop_scope ($self) { pop @{ $self->scopes } }

sub with_scope ($self, $cb) {
  my $scope = $self->push_scope;

  try {
    $cb->($scope);
  } finally {
    $self->pop_scope;
  };
}

sub get_scope ($self) {
  return $self->get_current_scope;
}

sub _invoke_client ($self, $method, @args) {
  my $client = $self->client;
  my $scope  = $self->get_current_scope;

  if ($client->can($method)) {
    $client->$method(@args, $scope);
  } else {
    warn "Unknown method: $method";
  }
}

sub _new_event_id ($self) {
  $self->_last_event_id(uuid4());
  return $self->_last_event_id;
}

sub capture_message (
  $self, $message,
  $level = Sentry::Severity->Info,
  $hint = undef
) {
  my $event_id = $self->_new_event_id();

  $self->_invoke_client('capture_message', $message, $level,
    { event_id => $event_id });

  return $event_id;
}

sub capture_exception ($self, $exception, $hint = undef) {
  my $event_id = $self->_new_event_id();

  $self->_invoke_client('capture_exception', $exception,
    { event_id => $event_id });

  return $event_id;
}

sub capture_event ($self, $event, $hint = {}) {
  my $event_id = $self->_new_event_id();

  $self->_invoke_client('capture_event', $event,
    { $hint->%*, event_id => $event_id });

  return $event_id;
}

sub add_breadcrumb ($self, $crumb, $hint = undef) {
  $self->get_current_scope->add_breadcrumb($crumb);
}

sub run ($self, $cb) {
  $cb->($self);
}

sub sample ($self, $transaction, $sampling_context) {
  my $client  = $self->client;
  my $options = ($client && $client->get_options) // {};

  #  nothing to do if there's no client or if tracing is disabled
  if (!$client || !$options->{traces_sample_rate}) {
    $transaction->sampled(0);
    return $transaction;
  }

  # if the user has forced a sampling decision by passing a `sampled` value in
  # their transaction context, go with that
  if (defined $transaction->sampled) {
    $transaction->tags({
      $transaction->tags->%*,
      __sentry_samplingMethod => Sentry::Tracing::SamplingMethod->Explicit,
    });

    return $transaction;
  }

  my $sample_rate;

  if (defined $sampling_context->{parent_sampled}) {
    $sample_rate = $sampling_context->{parent_sampled};
    $transaction->tags({
      $transaction->tags->%*,
      __sentry_samplingMethod => Sentry::Tracing::SamplingMethod->Inheritance,
    });
  } else {
    $sample_rate = $options->{traces_sample_rate};
    $transaction->tags({
      $transaction->tags->%*,
      __sentry_samplingMethod => Sentry::Tracing::SamplingMethod->Rate,
      __sentry_sampleRate     => $sample_rate,
    });
  }

  if (!$sample_rate) {
    logger->log(
      'Discarding transaction because a negative sampling decision was inherited or tracesSampleRate is set to 0',
      'Tracing'
    );
    $transaction->sampled(0);
    return $transaction;
  }

  # Now we roll the dice. Math.random is inclusive of 0, but not of 1, so
  # strict < is safe here. In case sampleRate is a boolean, the < comparison
  # will cause it to be automatically cast to 1 if it's true and 0 if it's
  # false.
  $transaction->sampled(rand() < $sample_rate);

  # if we're not going to keep it, we're done
  if (!$transaction->sampled) {
    logger->log(
      "Discarding transaction because it's not included in the random sample (sampling rate = $sample_rate)",
      'Tracing',
    );
    return $transaction;
  }

  logger->log(
    sprintf(
      'Starting %s transaction - %s',
      $transaction->op // '(unknown op)',
      $transaction->name
    ),
    'Tracing',
  );
  return $transaction;
}

sub start_transaction ($self, $context, $custom_sampling_context = {}) {
  my $transaction = Sentry::Tracing::Transaction->new(
    { $context->%*, _hub => $self, start_timestamp => time });

  return $self->sample(
    $transaction,
    {
      parent_sampled => $context->{parent_sampled},
      ($custom_sampling_context // {})->%*,
    }
  );
}

1;
