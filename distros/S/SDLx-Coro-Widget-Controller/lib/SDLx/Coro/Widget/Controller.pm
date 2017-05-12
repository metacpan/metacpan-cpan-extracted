package SDLx::Coro::Widget::Controller;

=head1 NAME

SDLx::Coro::Widget::Controller - Event loop with Coro yummyness

=head1 SYNOPSYS

  use SDLx::Coro::Widget::Controller;

  # More info coming soon!

=cut

use strict;
use base 'SDLx::Widget::Controller';

use Coro;
use AnyEvent;

our $VERSION = '0.01';

sub _event {
    my $self = shift;

    $self->SUPER::_event(@_);

    # Magical cede to other anyEvent stuff
    my $done = AnyEvent->condvar;
    my $delay = AnyEvent->timer( after => 0.00000001, cb => sub {  $done->send; cede();} );
    $done->recv;
}

sub run {
  my $self = shift;
  async { $self->SUPER::run(@_); };
  EV::loop();
}

1;

