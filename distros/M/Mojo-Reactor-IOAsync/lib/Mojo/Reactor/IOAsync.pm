package Mojo::Reactor::IOAsync;
use Mojo::Base 'Mojo::Reactor::Poll';

$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::IOAsync';

use Carp 'croak';
use IO::Async::Loop;
use IO::Async::Handle;
use IO::Async::Timer::Countdown;
use Mojo::Util 'md5_sum';
use Scalar::Util 'weaken';

use constant DEBUG => $ENV{MOJO_REACTOR_IOASYNC_DEBUG} || 0;

our $VERSION = '1.000';

my $IOAsync;

# Use IO::Async::Loop singleton for the first instance only
sub new {
	my $self = shift->SUPER::new;
	if ($IOAsync++) {
		$self->{loop} = IO::Async::Loop->really_new;
	} else {
		$self->{loop} = IO::Async::Loop->new;
		$self->{loop_singleton} = 1;
	}
	return $self;
}

sub DESTROY {
	my $self = shift;
	$self->reset;
	undef $IOAsync if $self->{loop_singleton};
}

sub again {
	my ($self, $id) = @_;
	croak 'Timer not active' unless my $timer = $self->{timers}{$id};
	$timer->{watcher}->reset;
}

sub io {
	my ($self, $handle, $cb) = @_;
	my $fd = fileno $handle;
	$self->{io}{$fd}{cb} = $cb;
	warn "-- Set IO watcher for $fd\n" if DEBUG;
	return $self->watch($handle, 1, 1);
}

sub one_tick {
	my $self = shift;
	
	# Just one tick
	local $self->{running} = 1 unless $self->{running};
	
	# Stop automatically if there is nothing to watch
	return $self->stop unless keys %{$self->{timers}} || keys %{$self->{io}} || $self->{loop}->notifiers;
	
	$self->{loop}->loop_once;
}

sub recurring { shift->_timer(1, @_) }

sub remove {
	my ($self, $remove) = @_;
	return !!0 unless defined $remove;
	if (ref $remove) {
		my $fd = fileno $remove;
		my $io = delete $self->{io}{$fd};
		if ($io) {
			warn "-- Removed IO watcher for $fd\n" if DEBUG;
			$io->{watcher}->remove_from_parent if $io->{watcher};
		}
		return !!$io;
	} else {
		my $timer = delete $self->{timers}{$remove};
		if ($timer) {
			warn "-- Removed timer $remove\n" if DEBUG;
			$timer->{watcher}->remove_from_parent if $timer->{watcher};
		}
		return !!$timer;
	}
}

sub reset {
	my $self = shift;
	$_->remove_from_parent for
		map { $_->{watcher} ? ($_->{watcher}) : () }
		values %{$self->{io}}, values %{$self->{timers}};
	$self->SUPER::reset;
}

sub stop {
	my $self = shift;
	delete $self->{running};
	$self->{loop}->loop_stop;
}

sub timer { shift->_timer(0, @_) }

sub watch {
	my ($self, $handle, $read, $write) = @_;
	
	my $fd = fileno $handle;
	croak 'I/O watcher not active' unless my $io = $self->{io}{$fd};
	if (my $w = $io->{watcher}) {
		$w->want_readready($read);
		$w->want_writeready($write);
	} else {
		weaken $self;
		my $on_read = sub { $self->_try('I/O watcher', $self->{io}{$fd}{cb}, 0) };
		my $on_write = sub { $self->_try('I/O watcher', $self->{io}{$fd}{cb}, 1) };
		my $w = $io->{watcher} = IO::Async::Handle->new(
			handle => $handle,
			on_read_ready => $on_read,
			on_write_ready => $on_write,
			want_readready => $read,
			want_writeready => $write,
		);
		$self->{loop}->add($w);
	}
	
	return $self;
}

sub _id {
	my $self = shift;
	my $id;
	do { $id = md5_sum 't' . $self->{loop}->time . rand 999 } while $self->{timers}{$id};
	return $id;
}

sub _timer {
	my ($self, $recurring, $after, $cb) = @_;
	
	my $id = $self->_id;
	weaken $self;
	my $on_expire = sub {
		my $w = shift;
		if ($recurring) {
			$w->start;
		} else {
			$w->remove_from_parent;
			delete $self->{timers}{$id};
		}
		#warn "-- Event fired for timer $id\n" if DEBUG;
		$self->_try('Timer', $cb);
	};
	my $w = $self->{timers}{$id}{watcher} = IO::Async::Timer::Countdown->new(
		delay => $after,
		on_expire => $on_expire,
	)->start;
	$self->{loop}->add($w);
	
	if (DEBUG) {
		my $is_recurring = $recurring ? ' (recurring)' : '';
		warn "-- Set timer $id after $after seconds$is_recurring\n";
	}
	
	return $id;
}

sub _try {
	my ($self, $what, $cb) = (shift, shift, shift);
	eval { $self->$cb(@_); 1 } or $self->emit(error => "$what failed: $@");
}

=head1 NAME

Mojo::Reactor::IOAsync - IO::Async backend for Mojo::Reactor

=head1 SYNOPSIS

  use Mojo::Reactor::IOAsync;

  # Watch if handle becomes readable or writable
  my $reactor = Mojo::Reactor::IOAsync->new;
  $reactor->io($first => sub {
    my ($reactor, $writable) = @_;
    say $writable ? 'First handle is writable' : 'First handle is readable';
  });

  # Change to watching only if handle becomes writable
  $reactor->watch($first, 0, 1);

  # Turn file descriptor into handle and watch if it becomes readable
  my $second = IO::Handle->new_from_fd($fd, 'r');
  $reactor->io($second => sub {
    my ($reactor, $writable) = @_;
    say $writable ? 'Second handle is writable' : 'Second handle is readable';
  })->watch($second, 1, 0);

  # Add a timer
  $reactor->timer(15 => sub {
    my $reactor = shift;
    $reactor->remove($first);
    $reactor->remove($second);
    say 'Timeout!';
  });

  # Start reactor if necessary
  $reactor->start unless $reactor->is_running;

  # Or in an application using Mojo::IOLoop
  use Mojo::Reactor::IOAsync;
  use Mojo::IOLoop;
  
  # Or in a Mojolicious application
  $ MOJO_REACTOR=Mojo::Reactor::IOAsync hypnotoad script/myapp

=head1 DESCRIPTION

L<Mojo::Reactor::IOAsync> is an event reactor for L<Mojo::IOLoop> that uses
L<IO::Async>. The usage is exactly the same as other L<Mojo::Reactor>
implementations such as L<Mojo::Reactor::Poll>. L<Mojo::Reactor::IOAsync> will
be used as the default backend for L<Mojo::IOLoop> if it is loaded before
L<Mojo::IOLoop> or any module using the loop. However, when invoking a
L<Mojolicious> application through L<morbo> or L<hypnotoad>, the reactor must
be set as the default by setting the C<MOJO_REACTOR> environment variable to
C<Mojo::Reactor::IOAsync>.

=head1 EVENTS

L<Mojo::Reactor::IOAsync> inherits all events from L<Mojo::Reactor::Poll>.

=head1 METHODS

L<Mojo::Reactor::IOAsync> inherits all methods from L<Mojo::Reactor::Poll> and
implements the following new ones.

=head2 new

  my $reactor = Mojo::Reactor::IOAsync->new;

Construct a new L<Mojo::Reactor::IOAsync> object.

=head2 again

  $reactor->again($id);

Restart timer. Note that this method requires an active timer.

=head2 io

  $reactor = $reactor->io($handle => sub {...});

Watch handle for I/O events, invoking the callback whenever handle becomes
readable or writable.

  # Callback will be invoked twice if handle becomes readable and writable
  $reactor->io($handle => sub {
    my ($reactor, $writable) = @_;
    say $writable ? 'Handle is writable' : 'Handle is readable';
  });

=head2 one_tick

  $reactor->one_tick;

Run reactor until an event occurs or no events are being watched anymore. See
L</"CAVEATS">.

  # Don't block longer than 0.5 seconds
  my $id = $reactor->timer(0.5 => sub {});
  $reactor->one_tick;
  $reactor->remove($id);

=head2 recurring

  my $id = $reactor->recurring(0.25 => sub {...});

Create a new recurring timer, invoking the callback repeatedly after a given
amount of time in seconds.

=head2 remove

  my $bool = $reactor->remove($handle);
  my $bool = $reactor->remove($id);

Remove handle or timer.

=head2 reset

  $reactor->reset;

Remove all handles and timers.

=head2 stop

  $reactor->stop;

Stop watching for I/O and timer events.

=head2 timer

  my $id = $reactor->timer(0.5 => sub {...});

Create a new timer, invoking the callback after a given amount of time in
seconds.

=head2 watch

  $reactor = $reactor->watch($handle, $readable, $writable);

Change I/O events to watch handle for with true and false values. Note that
this method requires an active I/O watcher.

  # Watch only for readable events
  $reactor->watch($handle, 1, 0);

  # Watch only for writable events
  $reactor->watch($handle, 0, 1);

  # Watch for readable and writable events
  $reactor->watch($handle, 1, 1);

  # Pause watching for events
  $reactor->watch($handle, 0, 0);

=head1 CAVEATS

When using L<Mojo::IOLoop> with L<IO::Async>, the event loop must be controlled
by L<Mojo::IOLoop> or L<Mojo::Reactor::IOAsync>, such as with the methods
L<Mojo::Reactor::Poll/"start">, L</"stop">, and L</"one_tick">. Starting or
stopping the event loop through L<IO::Async> will not provide required
functionality to L<Mojo::IOLoop> applications.

Externally-added L<IO::Async> notifiers will keep the L<Mojo::IOLoop> loop
running if they are added to the event loop as a notifier, see
L<IO::Async::Loop/"NOTIFIER MANAGEMENT">.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop>, L<IO::Async>

=cut

1;
