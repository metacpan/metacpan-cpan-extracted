package Mojo::Reactor::UV;
use Mojo::Base 'Mojo::Reactor';

$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::UV';

use Carp 'croak';
use Mojo::Reactor::Poll;
use Mojo::Util 'md5_sum';
use Scalar::Util 'weaken';
use UV;

use constant DEBUG => $ENV{MOJO_REACTOR_UV_DEBUG} || 0;

our $VERSION = '0.001';

my $UV;

sub DESTROY { undef $UV }

sub again {
	my $self = shift;
	croak 'Timer not active' unless my $timer = $self->{timers}{shift()};
	$self->_error if UV::timer_again($timer->{watcher}) < 0;
}

sub io {
	my ($self, $handle, $cb) = @_;
	my $fd = fileno $handle;
	$self->{io}{$fd}{cb} = $cb;
	warn "-- Set IO watcher for $fd\n" if DEBUG;
	return $self->watch($handle, 1, 1);
}

sub is_running { !!(shift->{running}) }

# We have to fall back to Mojo::Reactor::Poll, since UV is unique
sub new { $UV++ ? Mojo::Reactor::Poll->new : shift->SUPER::new }

sub next_tick {
	my ($self, $cb) = @_;
	push @{$self->{next_tick}}, $cb;
	$self->{next_timer} //= $self->timer(0 => \&_next);
	return undef;
}

sub one_tick {
	my $self = shift;
	# Just one tick
	local $self->{running} = 1 unless $self->{running};
	UV::run(UV::RUN_ONCE) or $self->stop;
}

sub recurring { shift->_timer(1, @_) }

sub remove {
	my ($self, $remove) = @_;
	return unless defined $remove;
	if (ref $remove) {
		my $fd = fileno $remove;
		if (exists $self->{io}{$fd}) {
			warn "-- Removed IO watcher for $fd\n" if DEBUG;
			my $w = delete $self->{io}{$fd}{watcher};
			UV::close($w) if $w;
		}
		return !!delete $self->{io}{$fd};
	} else {
		if (exists $self->{timers}{$remove}) {
			warn "-- Removed timer $remove\n" if DEBUG;
			my $w = delete $self->{timers}{$remove}{watcher};
			UV::close($w) if $w;
		}
		return !!delete $self->{timers}{$remove};
	}
}

sub reset {
	my $self = shift;
	UV::walk(sub { UV::close($_[0]) });
	delete @{$self}{qw(io next_tick next_timer timers)};
}

sub start {
	my $self = shift;
	$self->{running}++;
	$self->one_tick while $self->{running};
}

sub stop { delete shift->{running} }

sub timer { shift->_timer(0, @_) }

sub watch {
	my ($self, $handle, $read, $write) = @_;
	
	my $fd = fileno $handle;
	croak 'I/O watcher not active' unless my $io = $self->{io}{$fd};
	
	my $mode = 0;
	$mode |= UV::READABLE if $read;
	$mode |= UV::WRITABLE if $write;
	
	my $w;
	unless ($w = $io->{watcher}) { $w = $io->{watcher} = UV::poll_init($fd); }
	
	if ($mode == 0) { $self->_error if UV::poll_stop($w) < 0; }
	else {
		weaken $self;
		my $cb = sub {
			my ($status, $events) = @_;
			return $self->_error if $status < 0;
			$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 0)
				if UV::READABLE & $events;
			$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 1)
				if UV::WRITABLE & $events && $self->{io}{$fd};
		};
		$self->_error if UV::poll_start($w, $mode, $cb) < 0;
	}
	
	return $self;
}

sub _error {
	my $self = shift;
	$self->emit(error => sprintf "UV error: %s", UV::strerror(UV::last_error()));
}

sub _id {
	my $self = shift;
	my $id;
	do { $id = md5_sum 't' . UV::now() . rand 999 } while $self->{timers}{$id};
	return $id;
}

sub _next {
	my $self = shift;
	delete $self->{next_timer};
	while (my $cb = shift @{$self->{next_tick}}) { $self->$cb }
}

sub _timer {
	my ($self, $recurring, $after, $cb) = @_;
	$after *= 1000; # Intervals in milliseconds
	my $recur_after = $after;
	# Timer will not repeat with (integer) interval of 0
	$recur_after = 1 if $recurring and $after < 1;
	
	my $id = $self->_id;
	weaken $self;
	my $wrapper = sub {
		$self->remove($id) unless $recurring;
		$self->_try('Timer', $cb);
	};
	my $w = $self->{timers}{$id}{watcher} = UV::timer_init();
	$self->_error if UV::timer_start($w, $after, $recur_after, $wrapper) < 0;
	
	if (DEBUG) {
		my $is_recurring = $recurring ? ' (recurring)' : '';
		my $seconds = $after / 1000;
		warn "-- Set timer $id after $seconds seconds$is_recurring\n";
	}
		
	return $id;
}

sub _try {
	my ($self, $what, $cb) = (shift, shift, shift);
	eval { $self->$cb(@_); 1 } or $self->emit(error => "$what failed: $@");
}

1;

=encoding utf8

=head1 NAME

Mojo::Reactor::UV - UV backend for Mojo::Reactor

=head1 SYNOPSIS

  use Mojo::Reactor::UV;

  # Watch if handle becomes readable or writable
  my $reactor = Mojo::Reactor::UV->new;
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
  use Mojo::Reactor::UV;
  use Mojo::IOLoop;

  # Or in a Mojolicious application
  $ MOJO_REACTOR=Mojo::Reactor::UV hypnotoad script/myapp

=head1 DESCRIPTION

L<Mojo::Reactor::UV> is an event reactor for L<Mojo::IOLoop> that uses
C<libuv>. The usage is exactly the same as other L<Mojo::Reactor>
implementations such as L<Mojo::Reactor::Poll>. L<Mojo::Reactor::UV> will be
used as the default backend for L<Mojo::IOLoop> if it is loaded before
L<Mojo::IOLoop> or any module using the loop. However, when invoking a
L<Mojolicious> application through L<morbo> or L<hypnotoad>, the reactor must
be set as the default by setting the C<MOJO_REACTOR> environment variable to
C<Mojo::Reactor::UV>.

=head1 EVENTS

L<Mojo::Reactor::UV> inherits all events from L<Mojo::Reactor>.

=head1 METHODS

L<Mojo::Reactor::UV> inherits all methods from L<Mojo::Reactor> and implements
the following new ones.

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

=head2 is_running

  my $bool = $reactor->is_running;

Check if reactor is running.

=head2 new

  my $reactor = Mojo::Reactor::UV->new;

Construct a new L<Mojo::Reactor::UV> object.

=head2 next_tick

  my $undef = $reactor->next_tick(sub {...});

Invoke callback as soon as possible, but not before returning or other
callbacks that have been registered with this method, always returns C<undef>.

=head2 one_tick

  $reactor->one_tick;

Run reactor until an event occurs or no events are being watched anymore. Note
that this method can recurse back into the reactor, so you need to be careful.

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

=head2 start

  $reactor->start;

Start watching for I/O and timer events, this will block until L</"stop"> is
called or no events are being watched anymore.

  # Start reactor only if it is not running already
  $reactor->start unless $reactor->is_running;

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

When using L<Mojo::IOLoop> with L<UV>, the event loop must be controlled by
L<Mojo::IOLoop> or L<Mojo::Reactor::UV>, such as with the methods L</"start">,
L</"stop">, and L</"one_tick">. Starting or stopping the event loop through
L<UV> will not provide required functionality to L<Mojo::IOLoop> applications.

Care should be taken that file descriptors are not closed while being watched
by the reactor. They can be safely closed after calling L</"watch"> with
C<readable> and C<writable> set to 0, or after removing the handle with
L</"remove"> or L</"reset">.

On windows, C<libuv> can only watch sockets, not regular filehandles.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop>, L<UV>
