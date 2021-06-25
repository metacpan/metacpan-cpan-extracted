package Mojo::Reactor::UV;
use Mojo::Base 'Mojo::Reactor::Poll';

$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::UV';

use Carp 'croak';
use Mojo::Util qw(md5_sum steady_time);
use Scalar::Util qw(blessed weaken);
use UV;
use UV::Poll;
use UV::Timer;
use UV::Loop;

use constant DEBUG => $ENV{MOJO_REACTOR_UV_DEBUG} || 0;

our $VERSION = '1.901';

my $UV;

# Use UV::Loop singleton for the first instance only
sub new {
	my $self = shift->SUPER::new;
	if ($UV++) {
		$self->{loop} = UV::Loop->new;
	} else {
		$self->{loop} = UV::Loop->default_loop;
		$self->{loop_singleton} = 1;
	}
	return $self;
}

sub DESTROY { undef $UV if shift->{loop_singleton} }

sub again {
	my ($self, $id, $after) = @_;
	croak 'Timer not active' unless my $timer = $self->{timers}{$id};
	my $w = $timer->{watcher};
	if (defined $after) {
		$after *= 1000; # Intervals in milliseconds
		# Timer will not repeat with (integer) interval of 0
		$after = 1 if $after < 1;
		eval { $w->repeat($after); 1 } or $self->_error($@);
	}
	eval { $w->again; 1 } or $self->_error($@);
}

sub io {
	my ($self, $handle, $cb) = @_;
	my $fd = fileno($handle) // croak 'Handle is closed';
	# Must use existing watcher if present
	$self->{io}{$fd}{cb} = $cb;
	warn "-- Set IO watcher for $fd\n" if DEBUG;
	return $self->watch($handle, 1, 1);
}

sub one_tick {
	my $self = shift;
	# Just one tick
	local $self->{running} = 1 unless $self->{running};
	$self->{loop}->run(UV::Loop::UV_RUN_ONCE) or $self->stop;
}

sub recurring { shift->_timer(1, @_) }

sub remove {
	my ($self, $remove) = @_;
	return unless defined $remove;
	if (ref $remove) {
		my $fd = fileno($remove) // croak 'Handle is closed';
		if (exists $self->{io}{$fd}) {
			warn "-- Removed IO watcher for $fd\n" if DEBUG;
			my $w = delete $self->{io}{$fd}{watcher};
			$w->close if $w;
		}
		return !!delete $self->{io}{$fd};
	} else {
		if (exists $self->{timers}{$remove}) {
			warn "-- Removed timer $remove\n" if DEBUG;
			my $w = delete $self->{timers}{$remove}{watcher};
			$w->close if $w;
		}
		return !!delete $self->{timers}{$remove};
	}
}

sub reset {
	my $self = shift;
	$_->close for map { $_->{watcher} ? ($_->{watcher}) : () }
		values %{$self->{io}}, values %{$self->{timers}};
	$self->SUPER::reset;
}

sub timer { shift->_timer(0, @_) }

sub watch {
	my ($self, $handle, $read, $write) = @_;
	
	my $fd = fileno $handle;
	croak 'I/O watcher not active' unless my $io = $self->{io}{$fd};
	
	my $mode = 0;
	$mode |= UV::Poll::UV_READABLE if $read;
	$mode |= UV::Poll::UV_WRITABLE if $write;
	
	my $w;
	unless ($w = $io->{watcher}) { $w = $io->{watcher} = UV::Poll->new(loop => $self->{loop}, fd => $fd); }
	
	if ($mode == 0) { eval { $w->stop; 1 } or $self->_error($@); }
	else {
		weaken $self;
		my $cb = sub {
			my ($w, $status, $events) = @_;
			return $self->_error($status) if $status < 0;
			$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 0)
				if UV::Poll::UV_READABLE & $events;
			$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 1)
				if UV::Poll::UV_WRITABLE & $events && $self->{io}{$fd};
		};
		eval { $w->start($mode, $cb); 1 } or $self->_error($@);
	}
	
	return $self;
}

sub _error {
	my ($self, $err) = @_;
	if (blessed $err and $err->isa('UV::Exception')) {
		$self->emit(error => sprintf 'UV error: %s', $err->message);
	} elsif (!ref $err and $err < 0) {
		$self->emit(error => sprintf 'UV error: %s', UV::strerror($err));
	}
	return $err;
}

sub _id {
	my $self = shift;
	my $id;
	do { $id = md5_sum 't' . steady_time . rand } while $self->{timers}{$id};
	return $id;
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
	my $w = $self->{timers}{$id}{watcher} = UV::Timer->new(loop => $self->{loop});
	eval { $w->start($after, $recur_after, $wrapper); 1 } or $self->_error($@);
	
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

L<Mojo::Reactor::UV> inherits all events from L<Mojo::Reactor::Poll>.

=head1 METHODS

L<Mojo::Reactor::UV> inherits all methods from L<Mojo::Reactor::Poll> and
implements the following new ones.

=head2 new

  my $reactor = Mojo::Reactor::UV->new;

Construct a new L<Mojo::Reactor::UV> object.

=head2 again

  $reactor->again($id);
  $reactor->again($id, 0.5);

Restart timer and optionally change the invocation time. Note that this method
requires an active timer.

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
L<Mojo::IOLoop> or L<Mojo::Reactor::UV>, such as with the methods
L<Mojo::IOLoop/"start">, L<Mojo::IOLoop/"stop">, and L</"one_tick">. Starting
or stopping the event loop through L<UV> will not provide required
functionality to L<Mojo::IOLoop> applications.

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
