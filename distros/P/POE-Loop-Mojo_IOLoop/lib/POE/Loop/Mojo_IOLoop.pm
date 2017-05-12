use strict;
use warnings;

package POE::Loop::Mojo_IOLoop;

use POE::Loop::PerlSignals;

our $VERSION = '0.003';

=for poe_tests
BEGIN { $ENV{POE_EVENT_LOOP} = 'POE::Loop::Mojo_IOLoop' }
BEGIN { $ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::Poll' }
BEGIN { $ENV{POE_LOOP_USES_POLL} = 1 }
use Mojo::IOLoop;
sub skip_tests {
	if ($_[0] eq '00_info') {
		my $reactor = Mojo::IOLoop->singleton->reactor;
		diag("Using reactor $reactor");
	}
	return undef;
}

=cut

package
	POE::Kernel;

use Mojo::IOLoop;
use Time::HiRes;

use constant MOJO_DEBUG => $ENV{POE_LOOP_MOJO_DEBUG} || 0;

my $_timer_id;
my $_idle_id;
my @fileno_watcher;
my $_async_check;
my $DIE_MESSAGE;

# Loop construction and destruction.

sub loop_initialize {
	my $self = shift;
	
	my $reactor = Mojo::IOLoop->singleton->reactor;
	if ($reactor->isa('Mojo::Reactor::EV')) {
		# Workaround to ensure perl signal handlers are called
		$_async_check = EV::check(sub { });
		# EV will ignore exceptions unless this is set
		$EV::DIED = \&_die_handler;
	}
	
	warn "-- Initialized loop with reactor $reactor\n" if MOJO_DEBUG;
	
	unless (defined $_idle_id) {
		$_idle_id = Mojo::IOLoop->next_tick(\&_loop_resume_timer);
	}
}

sub loop_finalize {
	my $self = shift;
	
	warn "-- Finalized loop\n" if MOJO_DEBUG;
	
	foreach my $fd (0..$#fileno_watcher) {
		POE::Kernel::_warn(
			"Filehandle watcher for fileno $fd is defined during loop finalize"
		) if defined $fileno_watcher[$fd];
	}
	
	$self->loop_ignore_all_signals();
	undef $_async_check;
}

sub _die_handler {
	warn "-- Died $@\n" if MOJO_DEBUG;
	
	# EV doesn't let you rethrow an error here, so we have
	# to stop the loop and get the error later
	$DIE_MESSAGE = $@;
	
	# This will cause the EV::run call in loop_run to return,
	# and cause the process to die.
	EV::break();
}

# Signal handler maintenance functions.

sub loop_attach_uidestroy {
	# does nothing
}

# Maintain time watchers.

sub loop_resume_time_watcher {
	my ($self, $next_time) = @_;
	
	$next_time -= Time::HiRes::time;
	$next_time = 0 if $next_time < 0;
	
	warn "-- Resume time watcher in ${next_time}s\n" if MOJO_DEBUG;
	
	Mojo::IOLoop->remove($_timer_id) if defined $_timer_id;
	$_timer_id = Mojo::IOLoop->timer($next_time => \&_loop_event_callback);
}

sub loop_reset_time_watcher {
	my ($self, $next_time) = @_;
	
	warn "-- Reset time watcher to $next_time\n" if MOJO_DEBUG;
	
	Mojo::IOLoop->remove($_timer_id) if defined $_timer_id;
	undef $_timer_id;
	$self->loop_resume_time_watcher($next_time);
}

sub _loop_resume_timer {
	Mojo::IOLoop->remove($_idle_id) if defined $_idle_id;
	undef $_idle_id;
	$poe_kernel->loop_resume_time_watcher($poe_kernel->get_next_event_time());
}

sub loop_pause_time_watcher {
	# does nothing
}

# Maintain filehandle watchers.

sub loop_watch_filehandle {
	my ($self, $handle, $mode) = @_;
	my $fileno = fileno $handle;
	
	confess "POE::Loop::Mojo_IOLoop does not support MODE_EX" if $mode == MODE_EX;
	confess "Unknown mode $mode" unless $mode == MODE_RD or $mode == MODE_WR;
	
	warn "-- Watch filehandle $fileno, mode $mode\n" if MOJO_DEBUG;
	
	# Set up callback if needed
	unless (defined $fileno_watcher[$fileno]) {
		Mojo::IOLoop->singleton->reactor->io($handle => sub {
			my ($reactor, $writable) = @_;
			_loop_select_callback($fileno, $writable);
		});
	}
	
	$fileno_watcher[$fileno][$mode] = 1;
	
	_update_select_watcher($handle);
}

sub loop_ignore_filehandle {
	my ($self, $handle, $mode) = @_;
	my $fileno = fileno $handle;
	
	warn "-- Ignore filehandle $fileno, mode $mode\n" if MOJO_DEBUG;
	
	undef $fileno_watcher[$fileno][$mode];
	
	_update_select_watcher($handle);
}

sub loop_pause_filehandle {
	my ($self, $handle, $mode) = @_;
	my $fileno = fileno $handle;
	
	warn "-- Pause filehandle $fileno, mode $mode\n" if MOJO_DEBUG;
	
	$fileno_watcher[$fileno][$mode] = 0;
	
	_update_select_watcher($handle);
}

sub loop_resume_filehandle {
	my ($self, $handle, $mode) = @_;
	my $fileno = fileno $handle;
	
	warn "-- Resume filehandle $fileno, mode $mode\n" if MOJO_DEBUG;
	
	$fileno_watcher[$fileno][$mode] = 1;
	
	_update_select_watcher($handle);
}

sub _update_select_watcher {
	my ($handle) = @_;
	my $fileno = fileno $handle;
	
	my ($read, $write) = @{$fileno_watcher[$fileno]}[MODE_RD(),MODE_WR()];
	
	# Don't remove watcher unless both read and write have been ignored
	if (defined $read or defined $write) {
		Mojo::IOLoop->singleton->reactor->watch($handle, $read, $write);
	} else {
		Mojo::IOLoop->singleton->reactor->remove($handle);
		undef $fileno_watcher[$fileno];
	}
}

# Timer callback to dispatch events.

sub _loop_event_callback {
	my $self = $poe_kernel;
	
	warn "-- Timer callback\n" if MOJO_DEBUG;
	
	$self->_data_ev_dispatch_due();
	$self->_test_if_kernel_is_idle();
	
	undef $_timer_id;
	
	if ($self->get_event_count()) {
		$_idle_id = Mojo::IOLoop->next_tick(\&_loop_resume_timer);
	}
	
	# Transferring control back to Mojo::IOLoop; this is idle time.
}

# Mojo::IOLoop filehandle callback to dispatch selects.

sub _loop_select_callback {
	my $self = $poe_kernel;
	my ($fileno, $writable) = @_;
	
	my $mode = $writable ? MODE_WR : MODE_RD;
	
	# Make sure this callback is actually registered
	return unless defined $fileno_watcher[$fileno];
	
	# Workaround for write-only mode receiving read callback
	unless ($fileno_watcher[$fileno][$mode]) {
		if ($mode == MODE_RD and $fileno_watcher[$fileno][MODE_WR()]) {
			# Use write callback
			$mode = MODE_WR;
		} else {
			return;
		}
	}
	
	warn "-- Select callback for filehandle $fileno, mode $mode\n"
		if MOJO_DEBUG;
	
	$self->_data_handle_enqueue_ready($mode, $fileno);
	$self->_test_if_kernel_is_idle();
}

# The event loop itself.

sub loop_do_timeslice {
}

sub loop_run {
	warn "-- Loop run\n" if MOJO_DEBUG;
	Mojo::IOLoop->start;
	
	if (defined $DIE_MESSAGE) {
		my $message = $DIE_MESSAGE;
		undef $DIE_MESSAGE;
		die $message;
	}
}

sub loop_halt {
	warn "-- Loop halt\n" if MOJO_DEBUG;
	Mojo::IOLoop->stop;
}

=head1 NAME

POE::Loop::Mojo_IOLoop - a bridge that allows POE to be driven by Mojo::IOLoop

=head1 SYNOPSIS

See L<POE::Loop>.

 use POE qw(Loop::Mojo_IOLoop);
 
 use POE::Kernel { loop => 'Mojo::IOLoop' };
 
 BEGIN { $ENV{POE_EVENT_LOOP} = 'POE::Loop::Mojo_IOLoop' }
 use POE;

=head1 DESCRIPTION

L<POE::Loop::Mojo_IOLoop> implements the interface documented in L<POE::Loop>.
Therefore it has no documentation of its own. Please see L<POE::Loop> for more
details.

When using L<Mojo::IOLoop> with L<POE>, the loop must be set explicitly or
L<POE> will detect multiple event loops and fail. You can set the event loop
by setting the environment variable C<POE_EVENT_LOOP> to
C<POE::Loop::Mojo_IOLoop> before L<POE> is loaded, or by including it in the
C<use> directive when initially loading L<POE>. See
L<POE::Kernel/"Using POE with Other Event Loops"> for more information.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<POE>, L<POE::Loop>, L<Mojo::IOLoop>, L<POE::Loop::PerlSignals>

=cut

1;
