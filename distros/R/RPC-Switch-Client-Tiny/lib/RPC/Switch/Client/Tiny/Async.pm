# Async child handling for RPC::Switch::Client::Tiny
#
package RPC::Switch::Client::Tiny::Async;

use strict;
use warnings;
use IO::Socket;
use Time::HiRes qw(time);
use POSIX ":sys_wait_h"; # WNOHANG

our $VERSION = 1.16;

sub new {
	my ($class, %args) = @_;
	return bless {
		%args,
		jobqueue  => [], # queued async messages
		jobs      => {}, # active async childs
		finished  => {}, # finished childs to reap
	}, $class;
}

sub child_stop {
	my ($self, $pid, $status) = @_;
	my $child = $self->{finished}{$pid};
	my ($rc, $sig, $core) = ($status >> 8, $status & 127, $status & 128);
	my $stoptime = sprintf "%.02f", time() - $child->{start};
	my %runtime = (exists $child->{runtime}) ? (runtime => $child->{runtime}) : ();
	my %id = (exists $child->{id}) ? (id => exists $child->{id}) : ();
	my %reason = ();

	if ($^O eq 'MSWin32') { # cpantester: strawberry perl does not support WIF calls
		%reason = (reason => $child->{state});
	} elsif (WIFSTOPPED($status)) {
		warn "worker child $pid stopped\n";
		return 0;
	} elsif (WIFSIGNALED($status)) {
		%reason = (reason => "killed by signal $sig");
	} elsif (WIFEXITED($status) && $rc) {
		%reason = (reason => "exited with status $rc");
	} else {
		%reason = (reason => $child->{state});
	}
	$self->{trace_cb}->('END', {pid => $pid, %id, %runtime, stoptime => $stoptime, %reason}) if $self->{trace_cb};
	delete $self->{finished}{$pid};
	return 1;
}

sub childs_reap {
	my ($self, %opts) = @_;
	my $flags = $opts{nonblock} ? WNOHANG : 0;

	# A child is moved to the finished state in these cases:
	# 1) The child sent a valid reply on the pipe (done)
	# 2) The child sent an invalid reply or the pipe closed (error)
	# 3) The worker closes the pipe after rpcswitch.channel_gone (gone)
	# 4) The worker closes the pipe after rpcswitch socket closed (stopped)
	#
	foreach my $child (values %{$self->{finished}}) {
		my $res = waitpid($child->{pid}, $flags);
		if ($res == 0) {
			my $waittime = time() - $child->{start};

			# First try to send maskable signal to give child a
			# chance to cleanup resources, and send nonmaskable
			# sigkill to terminate child only after that.
			# (note: some nfs-syscalls might block nevertheless)
			#
			if (($waittime > 2) && ($child->{state} ne 'kill')) {
				warn "worker child $child->{pid}: still running after $child->{state} - send kill\n";
				kill 'KILL', $child->{pid};
				$child->{state} = 'kill';
			} elsif (($waittime > 1) && ($child->{state} ne 'term')) {
				warn "worker child $child->{pid}: still running after $child->{state} - send term\n";
				kill 'TERM', $child->{pid};
				$child->{state} = 'term';
			}
		} elsif ($res < 0) {
			warn "worker child $child->{pid}: disappeared" unless ($^O eq 'MSWin32');
			$self->child_stop($child->{pid}, 0);
		} else {
			$self->child_stop($child->{pid}, $?);
		}
	}
}

sub childs_kill {
	my ($self) = @_;

	foreach my $child (values %{$self->{finished}}) {
		if ($child->{state} ne 'kill') {
			kill 'KILL', $child->{pid}; # terminate non maskable
			$child->{state} = 'kill';
		}
	}
}

sub job_add {
	my ($self, $child, $msg_id, $meta) = @_;

	$child->{id} = $msg_id;
	$child->{start} = time();
	@$child{keys %$meta} = values %$meta;
	$self->{jobs}{$child->{reader}->fileno} = $child;
}

sub job_rem {
	my ($self, $child) = @_;

	$child->{runtime} = sprintf "%.02f", time() - $child->{start};
	$child->{start} = time();
	delete $self->{jobs}{$child->{reader}->fileno};
}

sub child_finish {
	my ($self, $child, $state) = @_;

	# The pipe close raises a sigpipe in the child
	# when the child is still alive and tries to write.
	#
	shutdown($child->{reader}, 2) or warn "worker child $child->{pid}: shutdown pipe failed: $!\n";
	close($child->{reader}) or warn "worker child $child->{pid}: close pipe failed: $!\n";
	delete $child->{reader};

	$child->{state} = $state;
	$child->{start} = time();
	$self->{finished}{$child->{pid}} = $child;
	return 1;
}

sub child_start {
	my ($self, $worker, $msg_id) = @_;
	my %id = (defined $msg_id) ? (id => $msg_id) : ();

	# Handle waitpid() explicitly instead of using open('-|');
	# see: https://perldoc.perl.org/perlipc#Safe-Pipe-Opens
	#
	socketpair(my $rd, my $wr, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair failed: $!";

	my $pid = fork();
	die "failed to fork: $!" unless defined $pid;

	if ($pid != 0) { # parent
		my $child = {reader => $rd, pid => $pid, start => time(), %id};
		$self->{trace_cb}->('RUN', {pid => $pid, %id}) if $self->{trace_cb};
		close($wr);
		return $child;
	}
	close($rd);
	$self->{jobqueue} = [];
	$self->{jobs} = {};
	$self->{finished} = {};
	local $SIG{TERM} = 'DEFAULT';

	# The child_handler returns an error code or dies.
	#
	my $ret = $worker->child_handler($wr);
	exit $ret;
}

sub msg_enqueue {
	my ($self, $msg) = @_;

	# queue message and start child from rpc_handler
	push(@{$self->{jobqueue}}, $msg);
}

sub msg_dequeue {
	my ($self) = @_;

	unless (keys %{$self->{jobs}} < $self->{max_async}) {
		return; # wait until job slot is avail
	}
	return shift(@{$self->{jobqueue}});
}

sub jobs_terminate {
	my ($self, $state, $filter) = @_;

	# Terminate active jobs & queued jobs
	# (no error reply since channel is closed)
	#
	my @childs = grep { $filter->($_) } values %{$self->{jobs}};
	foreach my $child (@childs) {
		$self->job_rem($child);
		$self->child_finish($child, $state);
	}
	my @msgs = grep { $filter->($_) } @{$self->{jobqueue}};
	if (@msgs) {
		$self->{jobqueue} = [grep { !$filter->($_) } @{$self->{jobqueue}}];
	}
	return (\@childs, \@msgs);
}

1;

__END__

=head1 NAME

RPC::Switch::Client::Tiny::Async - Child handling for async workers

=head1 SYNOPSIS

  use RPC::Switch::Client::Tiny::Async;

  sub trace_cb {
	my ($type, $msg) = @_;
	printf "%s: %s\n", $type, to_json($msg, {pretty => 0, canonical => 1});
  }

  my $async = RPC::Switch::Client::Tiny::Async->new(trace_cb => \&trace_cb);

  sub child_handler {
	my ($self, $fh) = @_;
	my $req = <$fh>;
	chomp $req;

	print "child $$ got: $req\n";
  	print $fh "pong\n";
	$fh->flush();
	exit 0;
  }
  my $worker = bless {};
  my $child = $async->child_start($worker);

  print {$child->{reader}} "ping\n";
  $child->{reader}->flush();
  my $res = readline($child->{reader});
  chomp $res;

  $async->child_finish($child, 'done');
  $async->childs_reap();

=head1 DESCRIPTION

The worker_child methods are private and handle
the childs used for the async client->work mode.

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut


