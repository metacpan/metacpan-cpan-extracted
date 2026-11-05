package Proc::Fork::Control;

#
#	 Copyright (C) 2014-2026 Colin Faber
#
#	 This program is free software: you can redistribute it and/or modify
#	 it under the terms of the GNU General Public License as published by
#	 the Free Software Foundation, version 2.
#
#	 This program is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	 GNU General Public License for more details.
#
#	 You should have received a copy of the GNU General Public License
#	 along with this program.  If not, see <https://www.gnu.org/licenses/>.
#	 A copy is included in this distribution as LICENSE.GPL.
#
#		 Original author: Colin Faber <cfaber@fpsn.net>
# Original creation date: 10/02/2014
#				 Version: 1.7
#

use 5.008;
use strict;
use warnings;

our $VERSION = '1.7';

use POSIX qw(WNOHANG setsid);
use Time::HiRes qw(usleep);

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	cfork
	cfork_wait
	cfork_wait_pid
	cfork_init
	cfork_exit
	cfork_exit_code
	cfork_maxchildren
	cfork_errstr
	cfork_is_child
	cfork_has_children
	cfork_nonblocking
	cfork_daemonize
	cfork_sleep
	cfork_usleep
	cfork_ssleep
	cfork_active_children
	cfork_kill_children
	cfork_list_children
	cfork_child_dob
);

our $HEAP = {};
our $errstr;

=encoding utf-8

=head1 NAME

Proc::Fork::Control - management front end to fork()

=head1 DESCRIPTION

Proc::Fork::Control manages C<fork()> for you. It caps how many children a
process may run, tracks those children, and can either block until they
exit or return as soon as they have been started.

The interface is a set of exported functions. Forking copies the
interpreter, so the module keeps its state in a process-global heap
instead of in an object.

=head1 SYNOPSIS

	use strict;
	use warnings;
	use Proc::Fork::Control;
	use Fcntl qw(:flock);

	# Allow 25 concurrent children of this process.
	cfork_init(25);

	# Nonblocking mode is what makes the cap queue workers. In the
	# default blocking mode, cfork() waits for the child before it
	# returns, so only one child exists at a time.
	cfork_nonblocking(1);

	for my $i (1 .. 50) {
		cfork(sub {
			cfork_init(2);
			cfork_nonblocking(1);

			for my $letter ('A' .. 'Z') {
				cfork(sub {
					flock(STDOUT, LOCK_EX);
					print STDOUT "Fork: $i: $letter\n";
					flock(STDOUT, LOCK_UN);
					cfork_exit(0);
				});
			}

			cfork_nonblocking(0);
			cfork_wait();
			cfork_exit(0);
		});
	}

	cfork_nonblocking(0);
	cfork_wait();

=head1 REQUIREMENTS

Perl 5.8 or newer, L<POSIX>, and L<Time::HiRes>. C<Time::HiRes> has been
required since version 1.3.

=head1 LIMITATIONS

The module installs its own C<$SIG{CHLD}> handler in each process that
calls C<cfork_init()> and is not itself a forked child. A handler you
installed earlier is replaced.

State is one heap per process. There is no object, and the module is not
a thread-safe work queue.

C<cfork_daemonize> changes the working directory to C</>.

=head1 METHODS

=head2 cfork(CODE, ...)

Fork once, when this process is under its child cap.

Each C<CODE> reference runs in the child, in order. If the child returns
from the last reference without calling C<cfork_exit>, it exits with
status 2. A reference that throws aborts the child with that error, and
later references do not run.

While the cap is full, C<cfork> waits for a slot. In the default blocking
mode it then waits for every child of this process, including the one it
just started, before it returns the child pid. Turn on
C<cfork_nonblocking> when the parent must keep more than one child at a
time. In that mode C<cfork> returns the pid as soon as the child has been
created.

The child starts with an empty child list and must call C<cfork_init>
itself before it calls C<cfork>. It does not inherit the parent's pids.

On success the parent receives the child pid. On failure C<cfork> returns
C<undef> and sets C<cfork_errstr>. A failed C<fork> is reported this way
and does not run the child code in the parent.

=cut

sub cfork {
	_errstr();

	my $heap = $Proc::Fork::Control::HEAP;
	my $max = $heap->{max_children};
	if (!defined $max || $max !~ /^\d+$/ || $max < 1) {
		return _errstr('cfork_init() not set');
	}

	$heap->{children} = 0 unless defined $heap->{children};

	my $i = 0;
	my $delay = 0;
	while (1) {
		my $cleaned = _cleanup();
		last if $heap->{children} < $heap->{max_children};

		if ($cleaned) {
			$i = 0;
			$delay = 0;
			next;
		}

		# Back off while the cap stays full, and cap the pause at 5ms.
		$delay ||= 5;
		$i++;
		$delay *= $i;
		$delay = 5000 if $delay > 5000;
		cfork_usleep($delay);
	}

	# fork returns undef on failure. Undef is false, so it has to be
	# rejected before the child branch or the parent would run it.
	my $pid = fork;
	if (!defined $pid) {
		return _errstr('fork failed: ' . $!);
	} elsif ($pid) {
		$heap->{cidlist}->{$pid} = time();
		$heap->{children}++;
	} else {
		# Drop the inherited parent list. Those pids are not this child's.
		cfork_init(undef, 1);
		$Proc::Fork::Control::HEAP->{is_child} = 1;
		$SIG{PIPE} = 'IGNORE';
		for my $code (@_) {
			if (ref($code) eq 'CODE') {
				$code->();
			}
		}

		cfork_exit(2);
	}

	cfork_wait();
	return $pid;
}

=head2 cfork_nonblocking(BOOL)

Turn nonblocking mode on when C<BOOL> is true, and off when it is false
or omitted.

In nonblocking mode C<cfork>, C<cfork_wait>, and C<cfork_wait_pid> return
without waiting for children to exit. The child cap still applies:
C<cfork> waits for a free slot before it forks.

Call C<cfork_nonblocking(0)> again when that stretch of work is finished,
then C<cfork_wait()>. The call returns the new mode, C<1> or C<0>.

=head3 Example

	cfork_nonblocking(1);

	cfork(sub {
		# parent returns while this child is still running
		cfork_exit(0);
	});

	cfork_nonblocking(0);
	cfork_wait();

=cut

sub cfork_nonblocking {
	my ($bool) = @_;
	$Proc::Fork::Control::HEAP->{nonblocking} = $bool ? 1 : 0;
	return $Proc::Fork::Control::HEAP->{nonblocking};
}

=head2 cfork_is_child()

Return C<1> when this process was started by C<cfork>, otherwise C<0>.

=cut

sub cfork_is_child {
	return $Proc::Fork::Control::HEAP->{is_child} ? 1 : 0;
}

=head2 cfork_has_children()

Return C<1> when this process still has children started by C<cfork>,
otherwise C<0>.

Children that have already been reaped do not count. In blocking mode
C<cfork> itself reaps before it returns, so call this from the parent
while nonblocking mode is on.

=cut

sub cfork_has_children {
	return cfork_active_children() ? 1 : 0;
}

=head2 cfork_errstr()

Return the last error string set by C<cfork>, or C<undef> if none has
been set. A later success does not clear it.

=cut

sub cfork_errstr {
	my ($err) = @_;
	# Boolean test: an undefined argument must not warn, and must not
	# replace a previous message.
	$Proc::Fork::Control::errstr = $err if $err;
	return $Proc::Fork::Control::errstr;
}

sub _errstr {
	my ($err) = @_;
	cfork_errstr($err);
	return;
}

=head2 cfork_init(CHILDREN)

Install the SIGCHLD reaper and set the maximum number of live children
of this process to C<CHILDREN>. Call it before any C<cfork>.

A later call in the parent, while children are still running, keeps
those children and adds C<CHILDREN> to the current maximum. A value of
C<0> does not change the maximum in that case. When no children are
running, the call replaces this process's heap and stores C<CHILDREN>
as the maximum, including zero. C<cfork> then fails until a positive
maximum is set.

Returns 1.

The second argument is internal. C<cfork> uses it so a new child drops
the pid list it inherited.

=cut

sub cfork_init {
	my ($max, $reset) = @_;
	my $heap = $Proc::Fork::Control::HEAP;
	my $ic = ($heap && $heap->{is_child}) ? 1 : 0;

	# A later init in the parent keeps workers that are still running.
	# The post-fork child passes $reset and starts from an empty list.
	if (!$reset && !$ic && $heap && $heap->{cidlist}) {
		my $alive = grep { $heap->{cidlist}->{$_} } keys %{ $heap->{cidlist} };
		if ($alive) {
			$heap->{max_children} += $max if $max;
			return 1;
		}
	}

	$Proc::Fork::Control::HEAP = {
		children => 0,
		cidlist	 => {},
		is_child => $ic,
	};
	$heap = $Proc::Fork::Control::HEAP;

	$SIG{CHLD} = \&Proc::Fork::Control::_sigchld if !$ic;

	# Zero is a real maximum. Only an omitted value leaves it unset.
	$heap->{max_children} = $max if defined $max;
	return 1;
}

cfork_init();

=head2 cfork_exit(STATUS)

Store C<STATUS> and exit the current process with it. An omitted status
exits 0. This does not return.

The stored status stays in the process that called C<cfork_exit>. The
parent observes it as the child's exit status after C<cfork_wait>, not
through C<cfork_exit_code>.

=cut

sub cfork_exit {
	my ($exit) = @_;
	$Proc::Fork::Control::HEAP->{exit} = $exit;
	exit(defined $exit ? $exit : 0);
}

=head2 cfork_exit_code()

Return the status last passed to C<cfork_exit> in this process, or
C<undef> if this process has not called it.

=cut

sub cfork_exit_code {
	return $Proc::Fork::Control::HEAP->{exit};
}

=head2 cfork_maxchildren(COUNT)

Set the maximum number of children to C<COUNT> when an argument is
given, including zero. With no argument, leave the maximum alone.
Returns the current maximum, or C<undef> if C<cfork_init> has not set
one.

=cut

sub cfork_maxchildren {
	my ($count) = @_;
	if (defined $count) {
		$Proc::Fork::Control::HEAP->{max_children} = $count;
	}
	return $Proc::Fork::Control::HEAP->{max_children};
}

=head2 cfork_wait(SECONDS)

Block until every child started by C<cfork> has exited.

C<SECONDS>, when it is a positive number, is a timeout. The call then
returns false if any child is still running when the timeout expires,
and C<1> if every child has exited. A missing or invalid timeout waits
without a deadline. The timeout is measured with L<Time::HiRes>, so a
fraction of a second is honored.

In nonblocking mode the call returns C<1> immediately and does not reap.

=cut

sub cfork_wait {
	my ($to) = @_;
	return 1 if $Proc::Fork::Control::HEAP->{nonblocking};

	my $deadline;
	if (defined $to && $to =~ /^\d+(?:\.\d+)?$/ && $to > 0) {
		$deadline = Time::HiRes::time() + $to;
	}

	my $heap = $Proc::Fork::Control::HEAP;
	my $i = 0;
	my $delay = 0;
	my $timed_out = 0;

	while (1) {
		my $cleaned = _cleanup();

		if (!$heap->{children}) {
			last;
		}
		if (defined $deadline && Time::HiRes::time() >= $deadline) {
			$timed_out = 1;
			last;
		}

		if ($cleaned) {
			$i = 0;
			$delay = 0;
			next;
		}

		$delay ||= 5;
		$i++;
		$delay *= $i;
		$delay = 5000 if $delay > 5000;
		cfork_usleep($delay);
	}

	return if $timed_out;
	return 1;
}

=head2 cfork_wait_pid(PID, ...)

Wait until every given pid has exited. Pids do not have to be children
started by this module. A pid that is not a positive integer is ignored.

In nonblocking mode the call returns C<1> immediately.

Returns 1. Dead processes are reaped while the call waits, so a zombie
child does not keep the loop running.

=cut

sub cfork_wait_pid {
	my (@pids) = @_;

	return 1 if $Proc::Fork::Control::HEAP->{nonblocking};

	while (1) {
		_cleanup();

		my @alive;
		for my $pid (@pids) {
			next unless defined $pid && $pid =~ /^\d+$/ && $pid > 0;
			push @alive, $pid if kill(0, $pid);
		}

		@pids = @alive;
		last if !@pids;

		cfork_usleep(5000);
	}

	return 1;
}

=head2 cfork_active_children()

Return the number of children started by C<cfork> that are still
running. Reaps exited children first.

=cut

sub cfork_active_children {
	_cleanup();
	my $n = $Proc::Fork::Control::HEAP->{children};
	return (defined $n && $n > 0) ? $n : 0;
}

=head2 cfork_daemonize(BOOL)

Detach the calling process.

The call changes directory to C</> and forks. The process that called
C<cfork_daemonize> then exits with status 4. The child becomes a new
session leader and returns C<1>.

When C<BOOL> is false or omitted, standard input, output, and error are
reopened on C</dev/null> before the fork. A true value leaves them
attached to whatever they are attached to now.

Failures die. This is the behavior the function has had since 1.2.

=cut

sub cfork_daemonize {
	my ($keep_stdio) = @_;

	chdir('/') || die "Can't chdir to /: $!\n";
	if (!$keep_stdio) {
		open STDIN,	 '<', '/dev/null' or die "Can't read /dev/null: $!\n";
		open STDOUT, '>', '/dev/null' or die "Can't write to /dev/null: $!\n";
		open STDERR, '>&', STDOUT	  or die "Can't dup stdout: $!\n";
	}

	my $pid = fork;
	die "Can't fork: $!\n" unless defined $pid;
	cfork_exit(4) if $pid;
	setsid || die "Can't start a new session: $!\n";
	return 1;
}

=head2 cfork_sleep(SECONDS)

Sleep for C<SECONDS> whole seconds. If a signal interrupts the sleep
early, the call keeps sleeping for the rest of the interval.

Returns the number of seconds slept, which is C<SECONDS> when the call
finishes the interval. Returns C<0> when C<SECONDS> is C<0>. Returns
C<undef> when C<SECONDS> is not a non-negative integer.

=cut

sub cfork_sleep {
	my ($seconds) = @_;
	return _sleep_for($seconds, sub { sleep($_[0]) });
}

=head2 cfork_usleep(MICROSECONDS)

Sleep for C<MICROSECONDS>. Interrupted sleeps are resumed until the
requested interval has elapsed, the same way as C<cfork_sleep>.

Returns the number of microseconds slept. Returns C<0> when the argument
is C<0>. Returns C<undef> when the argument is not a non-negative
integer.

=cut

sub cfork_usleep {
	my ($usec) = @_;
	return _sleep_for($usec, sub { usleep($_[0]) });
}

=head2 cfork_ssleep(SECONDS)

Sleep for C<SECONDS> whole seconds using C<select>, for environments
where C<sleep> returns early or not at all. A signal that wakes
C<select> does not end the wait; the call loops until the interval has
passed.

Returns C<SECONDS>, or C<0> when the argument is C<0>. Returns C<undef>
when the argument is not a non-negative integer.

=cut

sub cfork_ssleep {
	my ($sleep) = @_;
	return if !defined $sleep || $sleep !~ /^\d+$/;
	return 0 if $sleep == 0;

	my $end = Time::HiRes::time() + $sleep;
	while (1) {
		my $left = $end - Time::HiRes::time();
		last if $left <= 0;
		select(undef, undef, undef, $left);
	}
	return $sleep + 0;
}

=head2 cfork_kill_children(SIGNAL)

Send C<SIGNAL> to every child still tracked by this process. The signal
defaults to C<TERM>.

Returns the number of processes signaled, or C<0> when there are none.

=cut

sub cfork_kill_children {
	my ($sig) = @_;
	_cleanup();
	$sig = 'TERM' unless defined $sig && $sig ne '';

	my $list = $Proc::Fork::Control::HEAP->{cidlist} || {};
	my @pids = keys %{$list};
	return 0 unless @pids;
	return kill($sig, @pids);
}

=head2 cfork_list_children(AS_HASH)

Return the pids of children that are still running.

When C<AS_HASH> is true, return those pids paired with the epoch second
each child was started, as a list suitable for assignment to a hash.

=cut

sub cfork_list_children {
	my ($use_hash) = @_;
	_cleanup();

	my $list = $Proc::Fork::Control::HEAP->{cidlist} || {};
	if ($use_hash) {
		return %{$list};
	}
	return keys %{$list};
}

=head2 cfork_child_dob(PID)

Return the epoch second at which this process started C<PID> with
C<cfork>.

Return C<undef> when C<PID> is not a child still tracked here. Reaped
children are forgotten.

=cut

sub cfork_child_dob {
	my ($pid) = @_;
	_cleanup();
	return if !defined $pid || $pid !~ /^\d+$/;

	my $list = $Proc::Fork::Control::HEAP->{cidlist};
	return if !$list || !exists $list->{$pid} || !$list->{$pid};
	return $list->{$pid};
}

=head1 AUTHOR

Colin Faber, C<cfaber@fpsn.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2026 Colin Faber

The source of this module is released under the GNU General Public
License, version 2. The license text is in F<LICENSE.GPL>. This
distribution also includes the Artistic License 1.0 in F<LICENSE>, as it
has since the first public release.

=head1 SUPPORT

Please report bugs at
L<https://github.com/cfaber/Proc-Fork-Control/issues>.

=cut

# A zero or undefined return is not proof that the interval finished.
# Stop if the platform reports no progress, so a bad return cannot spin.
sub _sleep_for {
	my ($requested, $once) = @_;
	return if !defined $requested || $requested !~ /^\d+$/;
	return 0 if $requested == 0;

	my $left = $requested + 0;
	my $slept = 0;
	my $stalls = 0;

	while ($left > 0) {
		my $got = $once->($left);
		if (!defined $got || ref($got) || $got !~ /^-?\d+(?:\.\d+)?$/) {
			return $slept + $left;
		}

		$got += 0;
		if ($got <= 0) {
			$stalls++;
			return $slept if $stalls > 2;
			next;
		}

		$stalls = 0;
		$slept += $got;
		last if $got >= $left;
		$left -= $got;
	}

	return $slept;
}

sub _sigchld {
	my $ours;
	my $heap = $Proc::Fork::Control::HEAP;
	return unless $heap && $heap->{cidlist};

	while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
		if (exists $heap->{cidlist}->{$pid}) {
			$heap->{cidlist}->{$pid} = 0;
			$ours = 1;
		}
	}

	if ($ours) {
		$SIG{CHLD} = \&Proc::Fork::Control::_sigchld;
	}
	return;
}

# Drop reaped and vanished pids. Keys are copied first; deleting from a
# hash while iterating it can skip entries.
sub _cleanup {
	my $heap = $Proc::Fork::Control::HEAP;
	return 0 unless $heap && $heap->{cidlist};

	my $removed = 0;
	my @done = grep {
		defined $heap->{cidlist}->{$_} && $heap->{cidlist}->{$_} == 0
	} keys %{ $heap->{cidlist} };

	for my $pid (@done) {
		next unless exists $heap->{cidlist}->{$pid};
		delete $heap->{cidlist}->{$pid};
		$removed++;
		$heap->{children}-- if $heap->{children};
	}

	my @pids = keys %{ $heap->{cidlist} };
	for my $pid (@pids) {
		next unless exists $heap->{cidlist}->{$pid};
		next if kill(0, $pid);
		delete $heap->{cidlist}->{$pid};
		$removed++;
		$heap->{children}-- if $heap->{children};
	}

	return $removed;
}

1;
