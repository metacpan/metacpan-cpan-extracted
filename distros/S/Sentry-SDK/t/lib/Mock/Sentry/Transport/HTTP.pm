package Mock::Sentry::Transport::HTTP;
use Mojo::Base -base, -signatures;

use Test::More;

has events_sent => sub { [] };

sub send ($self, $event) {
  push $self->events_sent->@*, $event;
}

sub expect_to_have_sent ($self) {
  ok $self->events_sent->@* > 0;
}

sub expect_not_to_have_sent ($self) {
  is $self->events_sent->@*, 0;
}

sub expect_to_have_sent_once ($self) {
  is $self->events_sent->@*, 1;
}

sub expect_to_have_sent ($self, %data) {
  my $event = $self->events_sent->[0];

  is $event->{$_} => $data{$_} for keys %data;
}

1;
