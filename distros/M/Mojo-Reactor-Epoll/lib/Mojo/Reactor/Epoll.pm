package Mojo::Reactor::Epoll;
use Mojo::Base 'Mojo::Reactor::Poll';

$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::Epoll';

use Carp 'croak';
use Linux::Epoll;
use List::Util 'min';
use Mojo::Util qw(md5_sum steady_time);
use Scalar::Util 'weaken';
use Time::HiRes 'usleep';

use constant DEBUG => $ENV{MOJO_REACTOR_EPOLL_DEBUG} || 0;

our $VERSION = '0.011';

sub io {
	my ($self, $handle, $cb) = @_;
	my $fd = fileno($handle) // croak 'Handle is closed';
	$self->{io}{$fd}{cb} = $cb;
	warn "-- Set IO watcher for $fd\n" if DEBUG;
	return $self->watch($handle, 1, 1);
}

sub one_tick {
	my $self = shift;
	
	# Just one tick
	local $self->{running} = 1 unless $self->{running};
	
	# Wait for one event
	my $i;
	until ($i || !$self->{running}) {
		# Stop automatically if there is nothing to watch
		return $self->stop unless keys %{$self->{timers}} || keys %{$self->{io}};
		
		# Calculate ideal timeout based on timers
		my $min = min map { $_->{time} } values %{$self->{timers}};
		my $timeout = defined $min ? ($min - steady_time) : 0.5;
		$timeout = 0 if $timeout < 0;
		
		# I/O
		if (my $watched = keys %{$self->{io}}) {
			# Set max events to half the number of descriptors, to a minimum of 10
			my $maxevents = int $watched/2;
			$maxevents = 10 if $maxevents < 10;
			
			my $epoll = $self->{epoll} // $self->_create_epoll;

			my $count = $epoll->wait($maxevents, $timeout);
			$i += $count if defined $count;
		}
		
		# Wait for timeout if epoll can't be used
		elsif ($timeout) { usleep $timeout * 1000000 }
		
		# Timers (time should not change in between timers)
		my $now = steady_time;
		for my $id (keys %{$self->{timers}}) {
			next unless my $t = $self->{timers}{$id};
			next unless $t->{time} <= $now;
			
			# Recurring timer
			if ($t->{recurring}) { $t->{time} = $now + $t->{after} }
			
			# Normal timer
			else { $self->remove($id) }
			
			++$i and $self->_try('Timer', $t->{cb}) if $t->{cb};
		}
	}
}

sub recurring { shift->_timer(1, @_) }

sub remove {
	my ($self, $remove) = @_;
	if (ref $remove) {
		my $fd = fileno($remove) // croak 'Handle is closed';
		if (exists $self->{io}{$fd} and exists $self->{io}{$fd}{epoll_cb}) {
			$self->{epoll}->delete($remove);
		}
		warn "-- Removed IO watcher for $fd\n" if DEBUG;
		return !!delete $self->{io}{$fd};
	} else {
		warn "-- Removed timer $remove\n" if DEBUG;
		return !!delete $self->{timers}{$remove};
	}
}

sub reset {
	my $self = shift;
	delete @{$self}{qw(epoll pending_watch)};
	$self->SUPER::reset;
}

sub timer { shift->_timer(0, @_) }

sub watch {
	my ($self, $handle, $read, $write) = @_;
	
	my $fd = fileno $handle;
	croak 'I/O watcher not active' unless my $io = $self->{io}{$fd};

	my $epoll = $self->{epoll};
	unless (defined $epoll) {
		push @{$self->{pending_watch}}, [$handle, $read, $write];
		return $self;
	}
	
	my @events;
	push @events, 'in', 'prio' if $read;
	push @events, 'out' if $write;
	
	my $op = exists $io->{epoll_cb} ? 'modify' : 'add';
	
	weaken $self;
	my $cb = $io->{epoll_cb} // sub {
		my ($events) = @_;
		if ($events->{in} or $events->{prio} or $events->{hup} or $events->{err}) {
			return unless exists $self->{io}{$fd};
			$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 0);
		}
		if ($events->{out} or $events->{hup} or $events->{err}) {
			return unless exists $self->{io}{$fd};
			$self->_try('I/O watcher', $self->{io}{$fd}{cb}, 1);
		}
	};
	$epoll->$op($handle, \@events, $cb);
	
	# Cache callback for future modify operations, after successfully added to epoll
	$io->{epoll_cb} //= $cb;
	
	return $self;
}

sub _create_epoll {
	my $self = shift;
	$self->{epoll} = Linux::Epoll->new;
	$self->watch(@$_) for @{delete $self->{pending_watch} // []};
	return $self->{epoll};
}

sub _id {
	my $self = shift;
	my $id;
	do { $id = md5_sum 't' . steady_time . rand } while $self->{timers}{$id};
	return $id;
}

sub _timer {
	my ($self, $recurring, $after, $cb) = @_;
	
	my $id = $self->_id;
	my $timer = $self->{timers}{$id} = {
		cb        => $cb,
		after     => $after,
		recurring => $recurring,
		time      => steady_time + $after,
	};
	
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

1;

=head1 NAME

Mojo::Reactor::Epoll - epoll backend for Mojo::Reactor

=head1 SYNOPSIS

  use Mojo::Reactor::Epoll;

  # Watch if handle becomes readable or writable
  my $reactor = Mojo::Reactor::Epoll->new;
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
  use Mojo::Reactor::Epoll;
  use Mojo::IOLoop;
  
  # Or in a Mojolicious application
  $ MOJO_REACTOR=Mojo::Reactor::Epoll hypnotoad script/myapp

=head1 DESCRIPTION

L<Mojo::Reactor::Epoll> is an event reactor for L<Mojo::IOLoop> that uses the
L<epoll(7)> Linux subsystem. The usage is exactly the same as other
L<Mojo::Reactor> implementations such as L<Mojo::Reactor::Poll>.
L<Mojo::Reactor::Epoll> will be used as the default backend for L<Mojo::IOLoop>
if it is loaded before L<Mojo::IOLoop> or any module using the loop. However,
when invoking a L<Mojolicious> application through L<morbo> or L<hypnotoad>,
the reactor must be set as the default by setting the C<MOJO_REACTOR>
environment variable to C<Mojo::Reactor::Epoll>.

=head1 EVENTS

L<Mojo::Reactor::Epoll> inherits all events from L<Mojo::Reactor::Poll>.

=head1 METHODS

L<Mojo::Reactor::Epoll> inherits all methods from L<Mojo::Reactor::Poll> and
implements the following new ones.

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

The epoll notification facility is exclusive to Linux systems.

The epoll handle is not usable across forks, and this is not currently managed
for you, though it is not created until the loop is started to allow for
preforking deployments such as L<hypnotoad>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop>, L<Linux::Epoll>
