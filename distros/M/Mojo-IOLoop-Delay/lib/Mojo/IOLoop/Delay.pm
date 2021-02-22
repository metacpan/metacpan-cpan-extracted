package Mojo::IOLoop::Delay;
use Mojo::Base 'Mojo::Promise';

our $VERSION = '8.76';
$VERSION = eval $VERSION;

require Mojo::IOLoop;
unless (Mojo::IOLoop->can('delay')) {
  require Mojo::Util;

  Mojo::Util::monkey_patch 'Mojo::IOLoop', delay => sub {
    my $self = shift;
    my $loop = ref $self ? $self : $self->singleton;
    my $delay = Mojo::IOLoop::Delay->new->ioloop($loop);
    return @_ ? $delay->steps(@_) : $delay;
  };
}

sub begin {
  my ($self, $offset, $len) = @_;
  $self->{pending}++;
  my $id = $self->{counter}++;
  return sub { $self->_step($id, $offset // 1, $len, @_) };
}

sub pass { $_[0]->begin->(@_) }

sub steps {
  my ($self, @steps) = @_;
  $self->{steps} = \@steps;
  $self->ioloop->next_tick($self->begin);
  return $self;
}

sub _step {
  my ($self, $id, $offset, $len) = (shift, shift, shift, shift);

  $self->{args}[$id] = [@_ ? defined $len ? splice @_, $offset, $len : splice @_, $offset : ()];
  return $self if $self->{fail} || --$self->{pending} || $self->{lock};
  local $self->{lock} = 1;
  my @args = map {@$_} @{delete $self->{args}};

  $self->{counter} = 0;
  if (my $cb = shift @{$self->{steps}}) {
    unless (eval { $self->$cb(@args); 1 }) {
      my $err = $@;
      @{$self}{qw(fail steps)} = (1, []);
      return $self->reject($err);
    }
  }

  ($self->{steps} = []) and return $self->resolve(@args) unless $self->{counter};
  $self->ioloop->next_tick($self->begin)                 unless $self->{pending};
  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::IOLoop::Delay - (DISCOURAGED) Promises/A+ and flow-control helpers

=head1 SYNOPSIS

  use Mojo::IOLoop::Delay;

  # Synchronize multiple non-blocking operations
  my $delay = Mojo::IOLoop::Delay->new;
  $delay->steps(sub { say 'BOOM!' });
  for my $i (1 .. 10) {
    my $end = $delay->begin;
    Mojo::IOLoop->timer($i => sub {
      say 10 - $i;
      $end->();
    });
  }
  $delay->wait;

  # Sequentialize multiple non-blocking operations
  Mojo::IOLoop::Delay->new->steps(

    # First step (simple timer)
    sub ($delay) {
      Mojo::IOLoop->timer(2 => $delay->begin);
      say 'Second step in 2 seconds.';
    },

    # Second step (concurrent timers)
    sub ($delay, @args) {
      Mojo::IOLoop->timer(1 => $delay->begin);
      Mojo::IOLoop->timer(3 => $delay->begin);
      say 'Third step in 3 seconds.';
    },

    # Third step (the end)
    sub ($delay, @args) {
      say 'And done after 5 seconds total.';
    }
  )->wait;

=head1 DESCRIPTION

L<Mojo::IOLoop::Delay> adds flow-control helpers to L<Mojo::Promise>, which can help you avoid deep nested closures
that often result from continuation-passing style.

  use Mojo::IOLoop;

  # These deep nested closures are often referred to as "Callback Hell"
  Mojo::IOLoop->timer(3 => sub ($loop) {

    say '3 seconds';
    Mojo::IOLoop->timer(3 => sub ($loop) {

      say '6 seconds';
      Mojo::IOLoop->timer(3 => sub ($loop) {

        say '9 seconds';
        Mojo::IOLoop->stop;
      });
    });
  });

  Mojo::IOLoop->start;

The idea behind L<Mojo::IOLoop::Delay> is to turn the nested closures above into a flat series of closures. In the
example below, the call to L</"begin"> creates a code reference that we can pass to L<Mojo::IOLoop/"timer"> as a
callback, and that leads to the next closure in the series when executed.

  use Mojo::IOLoop;
  use Mojo::IOLoop::Delay; # adds Mojo::IOLoop->delay

  # Instead of nested closures we now have a simple chain of steps
  my $delay = Mojo::IOLoop->delay(
    sub ($delay) { Mojo::IOLoop->timer(3 => $delay->begin) },
    sub ($delay) {
      say '3 seconds';
      Mojo::IOLoop->timer(3 => $delay->begin);
    },
    sub ($delay) {
      say '6 seconds';
      Mojo::IOLoop->timer(3 => $delay->begin);
    },
    sub ($delay) { say '9 seconds' }
  );
  $delay->wait;

Another positive side effect of this pattern is that we do not need to call L<Mojo::IOLoop/"start"> and
L<Mojo::IOLoop/"stop"> manually, because we know exactly when our chain of L</"steps"> has reached the end. So
L<Mojo::Promise/"wait"> can stop the event loop automatically if it had to be started at all in the first place.

=head1 DISCOURAGED! WARNING!

This module has been extracted from L<Mojolicious> and was removed from it at the 9.0 release.
It is kept here for backwards compatibility purposes but there is no intention to maintain it further and it should be migrated away from as your earliest convenience.

Though there is no intention of removing it from CPAN in the future it should be treated as deprecated and the metadata will mark it as such.
It will receive no no-security-related changes going forward.

=head1 MOJO::IOLOOP CLASS METHOD CONSTRUCTOR

As of Mojolicious 9.0, the package L<Mojo::IOLoop> no longer provides a class constructor for delays.
If you want to use L<< Mojo::IOLoop->delay >> you must first load this class explicitly which will add it back.
You can also use C<-MMojo::IOLoop::Delay> at the command line to do so.

=head1 ATTRIBUTES

L<Mojo::IOLoop::Delay> inherits all attributes from L<Mojo::Promise>.

=head1 METHODS

L<Mojo::IOLoop::Delay> inherits all methods from L<Mojo::Promise> and implements the following new ones.

=head2 begin

  my $cb = $delay->begin;
  my $cb = $delay->begin($offset);
  my $cb = $delay->begin($offset, $len);

Indicate an active event by incrementing the event counter, the returned code reference can be used as a callback, and
needs to be executed when the event has completed to decrement the event counter again. When all code references
generated by this method have been executed and the event counter has reached zero, L</"steps"> will continue.

  # Capture all arguments except for the first one (invocant)
  my $delay = Mojo::IOLoop->delay(sub ($delay, $err, $stream) { ... });
  Mojo::IOLoop->client({port => 3000} => $delay->begin);
  $delay->wait;

Arguments passed to the returned code reference are spliced with the given offset and length, defaulting to an offset
of C<1> with no default length. The arguments are then combined in the same order L</"begin"> was called, and passed
together to the next step.

  # Capture all arguments
  my $delay = Mojo::IOLoop->delay(sub ($delay, $loop, $err, $stream) { ... });
  Mojo::IOLoop->client({port => 3000} => $delay->begin(0));
  $delay->wait;

  # Capture only the second argument
  my $delay = Mojo::IOLoop->delay(sub ($delay, $err) { ... });
  Mojo::IOLoop->client({port => 3000} => $delay->begin(1, 1));
  $delay->wait;

  # Capture and combine arguments
  my $delay = Mojo::IOLoop->delay(sub ($delay, $three_err, $three_stream, $four_err, $four_stream) { ... });
  Mojo::IOLoop->client({port => 3000} => $delay->begin);
  Mojo::IOLoop->client({port => 4000} => $delay->begin);
  $delay->wait;

=head2 pass

  $delay = $delay->pass;
  $delay = $delay->pass(@args);

Shortcut for passing values between L</"steps">.

  # Longer version
  $delay->begin(0)->(@args);

=head2 steps

  $delay = $delay->steps(sub {...}, sub {...});

Sequentialize multiple events, every time the event counter reaches zero a callback will run, the first one
automatically runs during the next reactor tick unless it is delayed by incrementing the event counter. This chain will
continue until there are no remaining callbacks, a callback does not increment the event counter or an exception gets
thrown in a callback. Finishing the chain will also result in the promise being fulfilled, or if an exception got
thrown it will be rejected.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHORS

The L<Mojolicious/AUTHORS>

=head1 CONTACT

While this module is no longer receiving non-security related maintenance, if you must contact someone about it please contact Joel Berger <jberger@cpan.org> or as a last resort contact the Mojolicious Core Team.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2021, Sebastian Riedel and others.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
