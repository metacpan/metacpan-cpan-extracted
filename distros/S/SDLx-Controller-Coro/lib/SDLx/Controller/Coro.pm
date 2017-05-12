package SDLx::Controller::Coro;

=head1 NAME

SDLx::Controller::Coro - Event loop with Coro yummyness

=head1 SYNOPSIS

  use SDLx::Controller::Coro;

  # More info coming soon!

=head1 DESCRIPTION

This module builds off of L<SDLx::Controller>, bringing Coro into the
event loop so that async events and routines will be processed.

=cut

use strict;
use base 'SDLx::Controller';

use EV;
use AnyEvent;
use Coro;
AnyEvent::detect; # Force AnyEvent to integrate Coro into EV

our $VERSION = '0.03';

sub _event {
  my $self = shift;

  $self->SUPER::_event(@_);

  # Give other AnyEvent/Coro/EV things a shot
  yield();
}

sub run {
  my $self = shift;
  async { $self->SUPER::run(@_); };
  EV::loop();
}

use Coro::AnyEvent;

sub yield {
  #Coro::AnyEvent::poll();
  Coro::AnyEvent::idle_upto(0.01);
}

1;

