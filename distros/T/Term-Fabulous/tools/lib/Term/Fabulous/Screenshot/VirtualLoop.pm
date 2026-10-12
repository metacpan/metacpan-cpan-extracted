package Term::Fabulous::Screenshot::VirtualLoop;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp qw(croak);
use Term::Fabulous::Screenshot::Clock;

BEGIN {
	croak 'Term::Fabulous::Screenshot::VirtualLoop: install the virtual clock before loading IO::Async (see Term::Fabulous::Screenshot::Clock)'
		unless Term::Fabulous::Screenshot::Clock::is_installed();
}

use parent 'IO::Async::Loop::Poll';

# Real seconds to wait for a child process before looking again. Virtual
# time stands still meanwhile, so the wait changes nothing but latency.
use constant CHILD_POLL_SECONDS => 0.02;

# IO::Async runs its timers by the clock, which Clock has made virtual.
# This loop never sleeps for a timer: when no input is ready and no timer
# is due, it moves the virtual clock straight to the next timer. Input
# that is ready is always handled before the clock moves, so the order of
# events depends only on the program, never on how fast the machine is.
#
# Child processes run in real time. While one runs, the clock stands
# still and the loop waits for the process (its output, its exit) in real
# time, so a command finishes at the same virtual moment on every run.

sub new ( $class, %params ) {
	my $self = $class->SUPER::new(%params);
	$self->{tf_running_children} = {};
	return $self;
}

sub loop_once ( $self, $timeout = undef ) {
	my $handled = $self->SUPER::loop_once(0);
	return $handled if $handled;

	return $self->SUPER::loop_once(CHILD_POLL_SECONDS) if %{ $self->{tf_running_children} };

	my $delay;
	$self->_adjust_timeout( \$delay );
	Term::Fabulous::Screenshot::Clock::advance($delay) if defined $delay;
	return 0;
}

sub watch_process ( $self, $pid, $code ) {
	return $self->SUPER::watch_process( $pid, $code ) if $pid == 0;    # a catch-all watch is no running process

	my $running = $self->{tf_running_children};
	$running->{$pid} = 1;
	return $self->SUPER::watch_process(
		$pid,
		sub (@exit) {
			delete $running->{$pid};
			return $code->(@exit);
		}
	);
}

sub unwatch_process ( $self, $pid ) {
	delete $self->{tf_running_children}{$pid};
	return $self->SUPER::unwatch_process($pid);
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::VirtualLoop - An IO::Async loop that runs
on the virtual clock

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Clock;
	BEGIN { Term::Fabulous::Screenshot::Clock::install(1780306860) }

	use Term::Fabulous::Screenshot::VirtualLoop;

	# Make it the loop that IO::Async::Loop->new returns everywhere.
	$IO::Async::Loop::ONE_TRUE_LOOP = Term::Fabulous::Screenshot::VirtualLoop->new;

=head1 DESCRIPTION

Maintainer tool, not installed. A subclass of L<IO::Async::Loop::Poll>
for the screenshot harness. Timers fire in virtual time (see
L<Term::Fabulous::Screenshot::Clock>): when nothing is ready, the loop
advances the clock to the next timer instead of sleeping. Ten seconds of
a 30 frames per second animation therefore take as long as computing
the 300 frames, and they always produce the same frames.

Ready input is handled before the clock moves. While a child process
watched with C<watch_process> runs (L<IO::Async::Process> watches every
process it starts), the clock stands still and the loop waits for the
process in real time.

The virtual clock must be installed before this module is loaded, or
loading dies: IO::Async imports C<Time::HiRes::time> when it is
compiled.

=head1 METHODS

=head2 loop_once

Handles everything that is ready now; when nothing was, waits for a
running child process, or advances the virtual clock to the next timer.
The C<$timeout> argument is ignored.

=head2 watch_process, unwatch_process

As in L<IO::Async::Loop>, and they keep track of the running child
processes.

=cut
