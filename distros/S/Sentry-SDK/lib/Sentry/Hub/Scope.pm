package Sentry::Hub::Scope;
use Mojo::Base -base, -signatures;

use Clone qw();
use Mojo::Util 'dumper';
use Sentry::Severity;
use Sentry::Tracing::Span;
use Sentry::Util 'merge';
use Time::HiRes;

has breadcrumbs            => sub { [] };
has contexts               => sub { {} };
has error_event_processors => sub { [] };
has event_processors       => sub { [] };
has extra                  => sub { {} };
has fingerprint            => sub { [] };
has level                  => Sentry::Severity->Info;
has span                   => undef;
has tags                   => sub { {} };
has transaction_name       => undef;
has user                   => undef;

sub set_span ($self, $span) {
  $self->span($span);
  return $self;
}

sub set_user ($self, $user) {
  $self->user($user);
}

sub set_extra ($self, $name, $value) {
  $self->extra->{$name} = $value;
}

sub set_extras ($self, $extras) {
  $self->extra = { %{ $self->extra }, %{$extras} };
}

sub set_tag ($self, $key, $value) {
  $self->tags->{$key} = $value;
}

sub set_tags ($self, $tags) {
  $self->tags({ $self->tags->%*, $tags->%* });
}

sub set_context ($self, $key, $context = undef) {
  if (not defined $context) {
    delete $self->contexts->{$key};
  } else {
    $self->contexts->{$key} = $context;
  }

  # $self->_notify_scope_listeners();

  return $self;
}

sub set_level ($self, $level) {
  $self->level($level);
}

sub set_transaction_name ($self, $name) {
  $self->transaction_name($name);
  return $self;
}

sub get_span ($self) {
  return $self->span;
}

sub set_fingerprint ($self, $fingerprint) {
  $self->fingerprint($fingerprint);
}

sub add_event_processor ($self, $event_processor) {
  push $self->event_processors->@*, $event_processor;
}

sub add_error_processor ($self, $error_event_processor) {
  push $self->error_event_processors->@*, $error_event_processor;
}

sub clear ($self) {

  # Resets a scope to default values while keeping all registered event
  # processors. This does not affect either child or parent scopes
}

sub add_breadcrumb ($self, $breadcrumb) {
  $breadcrumb->{timestamp} //= time;
  push @{ $self->breadcrumbs }, $breadcrumb;
}

sub clear_breadcrumbs ($self) {
  $self->breadcrumbs([]);
}

# Applies fingerprint from the scope to the event if there's one,
# uses message if there's one instead or get rid of empty fingerprint
sub _apply_fingerprint ($self, $event) {
  $event->{fingerprint} //= [];

  $event->{fingerprint} = [$event->{fingerprint}]
    if ref($event->{fingerprint} ne 'ARRAY');

  $event->{fingerprint} = [$event->{fingerprint}->@*, $self->fingerprint->@*];

  delete $event->{fingerprint} unless scalar $event->{fingerprint}->@*;
}

# Applies the scope data to the given event object. This also applies the event
# processors stored in the scope internally. Some implementations might want to
# set a max breadcrumbs count here.
sub apply_to_event ($self, $event, $hint = undef) {
  merge($event, $self, 'extra')    if $self->extra;
  merge($event, $self, 'tags')     if $self->tags;
  merge($event, $self, 'user')     if $self->user;
  merge($event, $self, 'contexts') if $self->contexts;

  $event->{level} //= $self->level           if $self->level;
  $event->{transaction} = $self->transaction if $self->transaction_name;

  if ($self->span) {
    $event->{request} = $self->span->request;

    $event->{contexts} = {
      trace => $self->span->get_trace_context(),
      ($event->{contexts} // {})->%*
    };

    if (my $transaction_name = $self->span->transaction->name) {
      $event->{tags}
        = { transaction => $transaction_name, ($event->{tags} // {})->%* };
    }
  }

  $self->_apply_fingerprint($event);

  $event->{breadcrumbs}
    = [($event->{breadcrumbs} // [])->@*, $self->breadcrumbs->@*];

  foreach my $processor ($self->event_processors->@*) {
    $processor->($event, $hint);
  }

  return $event;
}

sub clone ($self) {
  Clone::clone($self);
}

sub update ($self, $fields) {
  $self->$_($fields->{$_}) for keys $fields->%*;
}

1;
