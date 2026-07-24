# ABOUTME: Lifecycle helper for live functional tests: finds the snmp-query-engine
# ABOUTME: binary, runs snmpsim via uvx, allocates ports, and cleans up children.
package SQETest;

use strict;
use warnings;

use File::Spec;
use File::Temp ();
use FindBin;
use IO::Socket::INET;
use POSIX qw(setsid WNOHANG _exit);
use Net::SNMP::QueryEngine::AnyEvent;

my @children;

my $SNMPSIM = "snmpsim==1.2.2";
my $PYSMI   = "pysmi==2.0.0";

sub find_daemon
{
	if (defined $ENV{SQE_BINARY}) {
		return -x $ENV{SQE_BINARY} ? $ENV{SQE_BINARY} : undef;
	}
	for my $dir (File::Spec->path) {
		my $cand = File::Spec->catfile($dir, "snmp-query-engine");
		return $cand if -x $cand;
	}
	my $sibling = "$FindBin::Bin/../../snmp-query-engine/snmp-query-engine";
	return $sibling if -x $sibling;
	return undef;
}

sub find_uvx
{
	for my $dir (File::Spec->path) {
		my $cand = File::Spec->catfile($dir, "uvx");
		return $cand if -x $cand;
	}
	return undef;
}

sub skip_reason
{
	return "snmp-query-engine binary not found"
		. " (set SQE_BINARY or build ../snmp-query-engine)"
		unless find_daemon();
	return "uvx not found in PATH (needed to run snmpsim)"
		unless find_uvx();
	return undef;
}

sub free_port
{
	my $proto = shift;
	my $sock = IO::Socket::INET->new(
		LocalAddr => "127.0.0.1",
		LocalPort => 0,
		Proto     => $proto,
		($proto eq "tcp" ? (Listen => 1) : ()),
	) or die "cannot allocate free $proto port: $!";
	my $port = $sock->sockport;
	close $sock;
	return $port;
}

sub start
{
	my $class = shift;
	my $self = bless {
		agent_host  => "127.0.0.1",
		agent_port  => free_port("udp"),
		daemon_port => free_port("tcp"),
		logdir      => File::Temp->newdir("sqetest-XXXXXX", TMPDIR => 1),
	}, $class;

	$self->{snmpsim_pid} = spawn("$self->{logdir}/snmpsim.log",
		find_uvx(), "--from", $SNMPSIM, "--with", $PYSMI,
		"snmpsim-command-responder",
		"--data-dir=$FindBin::Bin/data",
		"--agent-udpv4-endpoint=$self->{agent_host}:$self->{agent_port}");
	$self->{daemon_pid} = spawn("$self->{logdir}/daemon.log",
		find_daemon(), "-q", "-p", $self->{daemon_port});

	$self->wait_ready;
	return $self;
}

sub client
{
	my $self = shift;
	return Net::SNMP::QueryEngine::AnyEvent->new(
		connect => ["127.0.0.1", $self->{daemon_port}]);
}

sub spawn
{
	my ($log, @cmd) = @_;
	my $pid = fork;
	die "fork: $!" unless defined $pid;
	if (!$pid) {
		$SIG{INT} = $SIG{TERM} = "DEFAULT";
		setsid();
		open STDIN, "<", "/dev/null"
			or do { print STDERR "reopen stdin: $!\n"; _exit(127) };
		open STDOUT, ">", $log
			or do { print STDERR "reopen stdout to $log: $!\n"; _exit(127) };
		open STDERR, ">&", \*STDOUT
			or do { print STDERR "reopen stderr: $!\n"; _exit(127) };
		exec @cmd or do {
			print STDERR "exec @cmd: $!\n";
			_exit(127);
		};
	}
	push @children, $pid;
	return $pid;
}

sub wait_ready
{
	my $self = shift;

	$self->wait_daemon_ready;

	# The first uvx run may download packages, hence the long deadline.
	# timeout/retries are per destination/client options, so this only
	# affects the probing client, not the clients the tests create.
	my $sqe = $self->client;
	$sqe->setopt($self->{agent_host}, $self->{agent_port},
		{ timeout => 300, retries => 1 }, sub {});
	$sqe->wait;
	my $deadline = time + 60;
	my $answered;
	while (time < $deadline && !$answered) {
		$sqe->get($self->{agent_host}, $self->{agent_port},
			["1.3.6.1.2.1.1.5.0"], sub {
				my ($h, $ok, $r) = @_;
				$answered = 1 if $ok && ref($r->[0][1]) ne "ARRAY";
			});
		$sqe->wait;
	}
	die "snmpsim did not answer on $self->{agent_host}:$self->{agent_port}:\n"
		. slurp("$self->{logdir}/snmpsim.log")
		unless $answered;
}

sub wait_daemon_ready
{
	my $self = shift;

	my $deadline = time + 10;
	my $conn;
	while (time < $deadline) {
		die "snmp-query-engine died during startup:\n"
			. slurp("$self->{logdir}/daemon.log")
			unless $self->daemon_alive;
		$conn = IO::Socket::INET->new(
			PeerAddr => "127.0.0.1",
			PeerPort => $self->{daemon_port},
			Proto    => "tcp");
		last if $conn;
		select undef, undef, undef, 0.1;
	}
	die "snmp-query-engine did not start on port $self->{daemon_port}:\n"
		. slurp("$self->{logdir}/daemon.log")
		unless $conn;
	close $conn;
	die "port $self->{daemon_port} answers but snmp-query-engine is dead"
		. " (foreign listener on the port?):\n"
		. slurp("$self->{logdir}/daemon.log")
		unless $self->daemon_alive;
}

sub daemon_alive
{
	my $self = shift;
	my $pid = $self->{daemon_pid} or return 0;
	return 1 unless waitpid($pid, WNOHANG) > 0;
	@children = grep { $_ != $pid } @children;
	delete $self->{daemon_pid};
	return 0;
}

sub kill_daemon
{
	my $self = shift;
	my $pid = delete $self->{daemon_pid} or return;
	reap($pid);
	@children = grep { $_ != $pid } @children;
}

sub restart_daemon
{
	my $self = shift;
	$self->kill_daemon;
	$self->{daemon_pid} = spawn("$self->{logdir}/daemon.log",
		find_daemon(), "-q", "-p", $self->{daemon_port});
	$self->wait_daemon_ready;
}

sub stop
{
	my $self = shift;
	for my $key (qw(snmpsim_pid daemon_pid)) {
		my $pid = delete $self->{$key} or next;
		reap($pid);
		@children = grep { $_ != $pid } @children;
	}
}

sub reap
{
	my $pid = shift;
	kill TERM => -$pid;
	kill TERM => $pid;
	for (1 .. 50) {
		return if waitpid($pid, WNOHANG) > 0;
		select undef, undef, undef, 0.1;
	}
	kill KILL => -$pid;
	kill KILL => $pid;
	waitpid $pid, 0;
}

sub slurp
{
	my $file = shift;
	open my $fh, "<", $file or return "(no log at $file: $!)";
	local $/;
	return scalar <$fh>;
}

$SIG{INT} = $SIG{TERM} = sub { exit 1 };

END { reap($_) for @children }

1;
