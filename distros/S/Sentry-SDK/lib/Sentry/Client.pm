package Sentry::Client;
use Mojo::Base -base, -signatures;

use Mojo::Home;
use Mojo::Util 'dumper';
use Sentry::DSN;
use Sentry::Hub::Scope;
use Sentry::Integration;
use Sentry::Logger 'logger';
use Sentry::SourceFileRegistry;
use Sentry::Stacktrace;
use Sentry::Transport::Http;
use Sentry::Util qw(uuid4 truncate);
use Time::HiRes;
use Try::Tiny;

has _dsn       => sub ($self) { Sentry::DSN->parse($self->_options->{dsn}) };
has _options   => sub { {} };
has _transport =>
  sub ($self) { Sentry::Transport::Http->new(dsn => $self->_dsn) };
has scope        => sub { Sentry::Hub::Scope->new };
has integrations => sub ($self) { $self->_options->{integrations} // [] };

sub setup_integrations ($self) {
  Sentry::Integration->setup($self->integrations);
}

#  (alternatively normal constructor) This takes typically an object with options + dsn.
sub from_config ($package, $config) { }

sub event_from_message ($self, $message, $level = Sentry::Severity->Info,
  $hint = undef) {
  my %event = (
    event_id => $hint && $hint->{event_id},
    level    => $level,
    message  => $message,
  );

  return \%event;
}

sub capture_message ($self, $message, $level = undef, $hint = undef,
  $scope = undef) {
  my $event = $self->event_from_message($message, $level, $hint);

  return $self->_capture_event($event, $hint, $scope);
}

sub capture_event ($self, $event, $hint = undef, $scope = undef) {
  my $event_id = ($hint // {})->{event_id};

  return $self->_capture_event($event, $hint, $scope);
}

sub _map_file_to_context ($self, $file, $line) {
  return $self->_source_file_registry->get_context_lines($file, $line);
}

sub is_file_of_app ($frame) {
  return scalar $frame->filename !~ m{\A /}xms;
}

sub _die { CORE::die ref $_[0] ? $_[0] : Mojo::Exception->new(shift)->trace }

sub event_from_exception ($self, $exception, $hint = undef, $scope = undef) {
  if (!ref($exception)) {
    $exception = Mojo::Exception->new($exception)->trace;
  }

  my $stacktrace = Sentry::Stacktrace->new({
    exception    => $exception,
    frame_filter => sub ($frame) {
      index($frame->package, 'Sentry') == -1
        && $frame->package !~ m{(Class::MOP|CGI::Carp|Try::Tiny)}xms;
    },
  });

  return {
    exception => {
      values => [{
        type       => ref($exception),
        value      => $exception->to_string,
        module     => ref($exception),
        stacktrace => $stacktrace,
      }]
    }
  };
}

sub capture_exception ($self, $exception, $hint = undef, $scope = undef) {
  my $event = $self->event_from_exception($exception, $hint);

  return $self->_capture_event($event, $hint, $scope);
}

sub _capture_event ($self, $event, $hint = undef, $scope = undef) {
  my $event_id;

  try {
    $event_id = $self->_process_event($event, $hint, $scope)->{event_id};
  } catch {
    logger->error($_);
  };

  return $event_id;
}

# Captures the event by merging it with other data with defaults from the
# client. In addition, if a scope is passed to this system, the data from the
# scope passes it to the internal transport.
# sub capture_event ($self, $event, $scope) { }

# Flushes out the queue for up to timeout seconds. If the client can guarantee
# delivery of events only up to the current point in time this is preferred.
# This might block for timeout seconds. The client should be disabled or
# disposed after close is called
sub close ($self, $timeout) { }

# Same as close difference is that the client is NOT disposed after calling flush
sub flush ($self, $timeout) { }

# Applies `normalize` function on necessary `Event` attributes to make them safe for serialization.
# Normalized keys:
# - `breadcrumbs.data`
# - `user`
# - `contexts`
# - `extra`
sub _normalize_event ($self, $event) {
  my %normalized = ($event->%*,);
  return \%normalized;
}

sub _apply_client_options ($self, $event) {
  my $options          = $self->_options;
  my $max_value_length = $options->{max_value_length} // 250;

  $event->{environment} //= $options->{environment} // 'production';
  $event->{dist}        //= $options->{dist};

  $event->{message} = truncate($event->{message}, $max_value_length)
    if $event->{message};

  return;
}

sub _apply_integrations_metadata ($self, $event) {
  $event->{sdk} //= {};

  my @integrations = $self->integrations->@*;
  $event->{sdk}->{integrations} = [map { ref($_) } @integrations]
    if @integrations;
}

# Adds common information to events.
#
# The information includes release and environment from `options`,
# breadcrumbs and context (extra, tags and user) from the scope.
#
# Information that is already present in the event is never overwritten. For
# nested objects, such as the context, keys are merged.
#
# @param event The original event.
# @param hint May contain additional information about the original exception.
# @param scope A scope containing event metadata.
# @returns A new event with more information.
sub _prepare_event ($self, $event, $scope, $hint = undef) {
  my %prepared = (
    $event->%*,
    sdk       => $self->_options->{_metadata}{sdk},
    platform  => 'perl',
    event_id  => $event->{event_id}  // ($hint // {})->{event_id} // uuid4(),
    timestamp => $event->{timestamp} // time,
  );

  $self->_apply_client_options(\%prepared);
  $self->_apply_integrations_metadata(\%prepared);

  # If we have scope given to us, use it as the base for further modifications.
  # This allows us to prevent unnecessary copying of data if `capture_context`
  # is not provided.
  my $final_scope = $scope;
  if (exists(($hint // {})->{capture_context})) {
    $final_scope = $scope->clone()->update($hint->{captureconsole});
  }

  # We prepare the result here with a resolved Event.
  my $result = \%prepared;

  # This should be the last thing called, since we want that
  # {@link Hub.addEventProcessor} gets the finished prepared event.
  if ($final_scope) {

    # In case we have a hub we reassign it.
    $result = $final_scope->apply_to_event(\%prepared, $hint);
  }

  return $self->_normalize_event($result);
}

sub _process_event ($self, $event, $hint, $scope) {
  my $prepared = $self->_prepare_event($event, $scope, $hint);

  my $is_transaction = ($event->{type} // '') eq 'transaction';

  die 'An event processor returned undef, will not send event.'
    unless $prepared;

  $self->_send_event($prepared);

  return $prepared;
}

sub _send_event ($self, $event) {
  $self->_transport->send($event);
  return;
}

1;

