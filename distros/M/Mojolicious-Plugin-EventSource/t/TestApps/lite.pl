#!/usr/bin/env perl
use Mojolicious::Lite;
BEGIN{ plugin 'Mojolicious::Plugin::EventSource' => timeout => 1 }

my $foi = {};

app->routes->event_source('/test1' => sub {
  my $self = shift;
  print $self->tx, $/;

  $self->emit("test1", "ok");
});

event_source('/test2' => sub {
  my $self = shift;
  print $self->tx, $/;

  $self->emit("test2", "ok");
});

event_source '/test3' => sub {
  my $self = shift;
  print $self->tx, $/;

  $self->emit("test3", "ok");
};

event_source '/test4' => sub {
  my $self = shift;
  print $self->tx, $/;

  $self->emit("test4", "ok");
} => undef;

event_source '/test5' => sub {
  my $self = shift;
  print $self->tx, $/;

  $self->emit("test5", "ok");
} => "bla";

event_source '/test6/:ble' => [ble => qr/\d+/] => sub {
  my $self = shift;
  print $self->tx, $/;

  $self->emit("test6", "num");
} => "bla";

event_source '/test6/:ble' => [ble => qr/\w+/] => sub {
  my $self = shift;
  print $self->tx, $/;

  $self->emit("test6", "str");
} => "bla";

app->start;
