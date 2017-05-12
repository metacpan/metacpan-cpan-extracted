package Mojo::Reactor::POE;

use POE; # Loaded early to avoid event loop confusion
BEGIN { POE::Kernel->run } # silence run() warning

use Mojo::Base 'Mojo::Reactor';

$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::POE';

use Carp 'croak';
use Mojo::Reactor::Poll;
use Mojo::Util qw(md5_sum steady_time);
use Scalar::Util 'weaken';

use constant { POE_IO_READ => 0, POE_IO_WRITE => 1 };
use constant DEBUG => $ENV{MOJO_REACTOR_POE_DEBUG} || 0;

our $VERSION = '0.009';

my $POE;

sub DESTROY {
	my $self = shift;
	$self->reset; # Close session
	undef $POE;
}

sub again {
	my ($self, $id) = @_;
	croak 'Timer not active' unless my $timer = $self->{timers}{$id};
	$timer->{time} = steady_time + $timer->{after};
	# If session doesn't exist, the time will be set when it starts
	$self->_session_call(mojo_adjust_timer => $id) if $self->_session_exists;
}

sub io {
	my ($self, $handle, $cb) = @_;
	$self->{io}{fileno $handle} = {cb => $cb};
	return $self->watch($handle, 1, 1);
}

sub is_running { !!(shift->{running}) }

# We have to fall back to Mojo::Reactor::Poll, since POE::Kernel is unique
sub new { $POE++ ? Mojo::Reactor::Poll->new : shift->SUPER::new }

sub next_tick {
	my ($self, $cb) = @_;
	push @{$self->{next_tick}}, $cb;
	$self->{next_timer} //= $self->timer(0 => \&_next);
	return undef;
}

sub one_tick {
	my $self = shift;
	$self->_init_session;
	
	# Stop automatically if there is nothing to watch
	return $self->stop unless keys %{$self->{timers}} || keys %{$self->{io}};
	
	# Just one tick
	local $self->{running} = 1 unless $self->{running};
	
	POE::Kernel->run_one_timeslice;
}

sub recurring { shift->_timer(1, @_) }

sub remove {
	my ($self, $remove) = @_;
	return unless defined $remove;
	if (ref $remove) {
		if (exists $self->{io}{fileno $remove}) {
			warn "-- Removed IO watcher for ".fileno($remove)."\n" if DEBUG;
			# If session doesn't exist, the watcher won't be re-added
			$self->_session_call(mojo_clear_io => fileno $remove) if $self->_session_exists;
		}
		return !!delete $self->{io}{fileno $remove};
	} else {
		if (exists $self->{timers}{$remove}) {
			warn "-- Removed timer $remove\n" if DEBUG;
			# If session doesn't exist, the timer won't be re-added
			$self->_session_call(mojo_clear_timer => $remove) if $self->_session_exists;
		}
		return !!delete $self->{timers}{$remove};
	}
}

sub reset {
	my $self = shift;
	# If session doesn't exist, watchers won't be re-added
	if ($self->_session_exists) {
		$self->_session_call('mojo_clear_timers');
		$self->_session_call(mojo_clear_io => $_) for keys %{$self->{io}};
	}
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
	
	croak 'I/O watcher not active' unless my $io = $self->{io}{fileno $handle};
	$io->{handle} = $handle;
	$io->{read} = $read;
	$io->{write} = $write;
	
	warn "-- Set IO watcher for ".fileno($handle)."\n" if DEBUG;
	
	$self->_init_session->_session_call(mojo_set_io => fileno $handle);
	
	return $self;
}

sub _id {
	my $self = shift;
	my $id;
	do { $id = md5_sum 't' . steady_time . rand 999 } while $self->{timers}{$id};
	return $id;
}

sub _next {
	my $self = shift;
	delete $self->{next_timer};
	while (my $cb = shift @{$self->{next_tick}}) { $self->$cb }
}

sub _timer {
	my ($self, $recurring, $after, $cb) = @_;
	
	my $id = $self->_id;
	my $timer = $self->{timers}{$id}
		= {cb => $cb, after => $after, time => steady_time + $after};
	$timer->{recurring} = $after if $recurring;
	
	if (DEBUG) {
		my $is_recurring = $recurring ? ' (recurring)' : '';
		warn "-- Set timer $id after $after seconds$is_recurring\n";
	}
	
	$self->_init_session->_session_call(mojo_set_timer => $id);
	
	return $id;
}

sub _try {
	my ($self, $what, $cb) = (shift, shift, shift);
	eval { $self->$cb(@_); 1 } or $self->emit(error => "$what failed: $@");
}

sub _init_session {
	my $self = shift;
	unless ($self->_session_exists) {
		my $session = POE::Session->create(
			inline_states => {
				_start				=> \&_event_start,
				_stop				=> \&_event_stop,
				mojo_set_timer 		=> \&_event_set_timer,
				mojo_clear_timer	=> \&_event_clear_timer,
				mojo_adjust_timer	=> \&_event_adjust_timer,
				mojo_clear_timers	=> \&_event_clear_timers,
				mojo_set_io			=> \&_event_set_io,
				mojo_clear_io		=> \&_event_clear_io,
				mojo_timer			=> \&_event_timer,
				mojo_io				=> \&_event_io,
			},
			heap => { mojo_reactor => $self },
		);
		weaken $session->get_heap()->{mojo_reactor};
		$self->{session_id} = $session->ID;
	}
	return $self;
}

sub _session_exists {
	my $self = shift;
	return defined $self->{session_id};
}

sub _session_call {
	my $self = shift;
	croak 'Session call on nonexistent session' unless defined $self->{session_id};
	POE::Kernel->call($self->{session_id}, @_);
	return $self;
}

sub _event_start {
	my $self = $_[HEAP]{mojo_reactor};
	my $session = $_[SESSION];
	
	warn "-- POE session started\n" if DEBUG;
}

sub _event_stop {
	my $self = $_[HEAP]{mojo_reactor};
	
	warn "-- POE session stopped\n" if DEBUG;
	
	delete $self->{session_id} if $self;
}

sub _event_set_timer {
	my $self = $_[HEAP]{mojo_reactor};
	my $id = $_[ARG0];
	return unless exists $self->{timers}{$id}
		and defined $self->{timers}{$id}{time};
	my $timer = $self->{timers}{$id};
	my $delay_time = $timer->{time} - steady_time;
	my $poe_id = POE::Kernel->delay_set(mojo_timer => $delay_time, $id);
	$timer->{poe_id} = $poe_id;
	
	warn "-- Set POE timer $poe_id in $delay_time seconds\n" if DEBUG;
}

sub _event_clear_timer {
	my $self = $_[HEAP]{mojo_reactor};
	my $id = $_[ARG0];
	return unless exists $self->{timers}{$id}
		and defined $self->{timers}{$id}{poe_id};
	my $timer = $self->{timers}{$id};
	POE::Kernel->alarm_remove($timer->{poe_id});
	
	warn "-- Cleared POE timer $timer->{poe_id}\n" if DEBUG;
}

sub _event_adjust_timer {
	my $self = $_[HEAP]{mojo_reactor};
	my $id = $_[ARG0];
	return unless exists $self->{timers}{$id}
		and defined $self->{timers}{$id}{time}
		and defined $self->{timers}{$id}{poe_id};
	my $timer = $self->{timers}{$id};
	my $new_delay = $timer->{time} - steady_time;
	POE::Kernel->delay_adjust($timer->{poe_id}, $new_delay);
	
	warn "-- Adjusted POE timer $timer->{poe_id} to $new_delay seconds\n"
		if DEBUG;
}

sub _event_clear_timers {
	my $self = $_[HEAP]{mojo_reactor} // return;
	POE::Kernel->alarm_remove_all;
	
	warn "-- Cleared all POE timers\n" if DEBUG;
}

sub _event_set_io {
	my $self = $_[HEAP]{mojo_reactor};
	my $fd = $_[ARG0];
	return unless exists $self->{io}{$fd}
		and defined $self->{io}{$fd}{handle};
	my $io = $self->{io}{$fd};
	if ($io->{read}) {
		POE::Kernel->select_read($io->{handle}, 'mojo_io');
	} else {
		POE::Kernel->select_read($io->{handle});
	}
	if ($io->{write}) {
		POE::Kernel->select_write($io->{handle}, 'mojo_io');
	} else {
		POE::Kernel->select_write($io->{handle});
	}
	
	warn "-- Set POE IO watcher for $fd " .
		"with read: $io->{read}, write: $io->{write}\n" if DEBUG;
}

sub _event_clear_io {
	my $self = $_[HEAP]{mojo_reactor};
	my $fd = $_[ARG0];
	return unless exists $self->{io}{$fd}
		and defined $self->{io}{$fd}{handle};
	my $io = $self->{io}{$fd};
	POE::Kernel->select_read($io->{handle});
	POE::Kernel->select_write($io->{handle});
	delete $io->{handle};
	
	warn "-- Cleared POE IO watcher for $fd\n" if DEBUG;
}

sub _event_timer {
	my $self = $_[HEAP]{mojo_reactor};
	my $id = $_[ARG0];
	
	my $timer = $self->{timers}{$id};
	warn "-- Event fired for timer $id\n" if DEBUG;
	if (exists $timer->{recurring}) {
		$timer->{time} = steady_time + $timer->{recurring};
		$self->_init_session->_session_call(mojo_set_timer => $id);
	} else {
		delete $self->{timers}{$id};
	}
	
	$self->_try('Timer', $timer->{cb});
}

sub _event_io {
	my $self = $_[HEAP]{mojo_reactor};
	my ($handle, $mode) = @_[ARG0, ARG1];
	
	my $io = $self->{io}{fileno $handle};
	#warn "-- Event fired for IO watcher ".fileno($handle)."\n" if DEBUG;
	if ($mode == POE_IO_READ) {
		$self->_try('I/O watcher', $io->{cb}, 0);
	} elsif ($mode == POE_IO_WRITE) {
		$self->_try('I/O watcher', $io->{cb}, 1);
	} else {
		die "Unknown POE I/O mode $mode";
	}
}

1;

=head1 NAME

Mojo::Reactor::POE - POE backend for Mojo::Reactor

=head1 SYNOPSIS

  use Mojo::Reactor::POE;

  # Watch if handle becomes readable or writable
  my $reactor = Mojo::Reactor::POE->new;
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
  use POE qw(Loop::IO_Poll);
  use Mojo::Reactor::POE;
  use Mojo::IOLoop;
  
  # Or in a Mojolicious application
  $ MOJO_REACTOR=Mojo::Reactor::POE POE_EVENT_LOOP=POE::Loop::IO_Poll hypnotoad script/myapp

=head1 DESCRIPTION

L<Mojo::Reactor::POE> is an event reactor for L<Mojo::IOLoop> that uses L<POE>.
The usage is exactly the same as other L<Mojo::Reactor> implementations such as
L<Mojo::Reactor::Poll>. L<Mojo::Reactor::POE> will be used as the default
backend for L<Mojo::IOLoop> if it is loaded before L<Mojo::IOLoop> or any
module using the loop. However, when invoking a L<Mojolicious> application
through L<morbo> or L<hypnotoad>, the reactor must be set as the default by
setting the C<MOJO_REACTOR> environment variable to C<Mojo::Reactor::POE>.

Note that if L<POE> detects multiple potential event loops it will fail. This
includes L<IO::Poll> and L<Mojo::IOLoop> (loaded by L<Mojolicious>) if the
appropriate L<POE::Loop> modules are installed. To avoid this, load L<POE>
before any L<Mojolicious> module, or specify the L<POE> event loop explicitly.
This means that for L<Mojolicious> applications invoked through L<morbo> or
L<hypnotoad>, the L<POE> event loop may also need to be set in the environment.
See L<POE::Kernel/"Using POE with Other Event Loops">.

=head1 EVENTS

L<Mojo::Reactor::POE> inherits all events from L<Mojo::Reactor>.

=head1 METHODS

L<Mojo::Reactor::POE> inherits all methods from L<Mojo::Reactor> and implements
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

  my $reactor = Mojo::Reactor::POE->new;

Construct a new L<Mojo::Reactor::POE> object.

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
called or no events are being watched anymore. See L</"CAVEATS">.

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

When using L<Mojo::IOLoop> with L<POE>, the event loop must be controlled by
L<Mojo::IOLoop> or L<Mojo::Reactor::POE>, such as with the methods L</"start">,
L</"stop">, and L</"one_tick">. Starting or stopping the event loop through
L<POE> will not provide required functionality to L<Mojo::IOLoop> applications.

Externally-added sessions will not keep the L<Mojo::IOLoop> running if
L<Mojo::Reactor::POE> has nothing left to watch. This can be worked around by
adding a recurring timer for the reactor to watch.

=head1 BUGS

L<POE> has a complex session system which may lead to bugs when used in this
manner. Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop>, L<POE>
