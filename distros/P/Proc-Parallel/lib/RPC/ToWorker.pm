
package RPC::ToWorker;

use strict;
use warnings;
require Exporter;
use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);
use Tie::Function::Examples qw(%q_perl);
use IO::Event;
use IO::Event::Callback;
use Eval::LineNumbers qw(eval_line_numbers);
use Carp qw(confess);
use IO::Handle;
use Socket;
use IO::Event::Callback;
use Proc::Parallel::RemoteKiller;
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(time);
require POSIX;

our $VERSION = 0.601;

our @EXPORT = qw(do_remote_job);
our @ISA = qw(Exporter);

our $command = 'perl';

our $max_retry = 10;

my $timer_interval = 5;
my $reconnect_timeout = 7200;
my $listen_port = 28328;
my $listener;
my $poll_interval = 15;

our $remote_killer;

my %waiting;

our $debug = 0;
our $debug_create = 0;

my %forced_polling;
my $last_poll = 0;
our $doing_force_poll = 1;

sub force_poll
{
	# work around a bug in IO::Event or maybe Event
	return if $doing_force_poll;
	return $last_poll + $poll_interval < time;
	local $doing_force_poll = 1;
	$last_poll = time;

	print STDERR "--------------------------------- forced poll start ----------------------------\n";

	for my $a (keys %forced_polling) {
		my $ioe = $forced_polling{$a};
		if ($ioe) {
			$ioe->ie_input();
		} else {
			delete $forced_polling{$a};
		}
	}

	print STDERR "--------------------------------- forced poll end ------------------------------\n";
}

sub do_remote_job
{
	my (%params) = @_;

	$params{can_retry} = 1 unless defined $params{can_retry};
	my $can_retry	= $params{can_retry};
	my $host	= $params{host};
	my $when_done	= $params{when_done}	|| confess "when_done is a required parameter";
	my $data	= $params{data};
	my $chdir	= $params{chdir}	||= '.';
	my $eval	= $params{eval};
	my $desc	= $params{desc}		||= "job on $host";
	my $prefix	= $params{prefix}	||= "$host:";
	my $preload	= $params{preload}	||= [];
	my $prequel	= $params{prequel}	||= '';
	my $alldone	= bless { %params }, 'RPC::ToWorker::AllDone';
	my $status	= $params{status}	||= sub { 0; };
	$params{failure} ||= sub {
		print STDERR "DIE DIE DIE DIE DIE: $desc: @_";
		# exit 1; hangs!
		POSIX::_exit(1);
	};
	my $died_at	= $params{died_at}	||= $params{failure};

	$params{alldone} = $alldone;

	$preload = [ split(' ', $preload) ] unless ref $preload;

	while(! $listener) {
		$listener = IO::Event::Socket::INET->new(
			Listen => 100,
			Proto => 'tcp',
			LocalPort => ++$listen_port,
		);
		unless ($listener) {
			warn "# Cannot listen on port $listen_port: $!";
			redo;
		}
		my $timer = IO::Event->timer(
			interval	=> $timer_interval,
			cb		=> sub {
				for my $e (keys %waiting) {
					my $r = $waiting{$e};
					next if time < $r->{start_time} + $reconnect_timeout;
					next if $r->{alldone}{failed};
					if ($r->{alldone}{compile_finished} && $can_retry && ! $r->{alldone}{master_go} && $can_retry < $max_retry) {
						$r->{alldone}->{retrying} = 1;
						$r->{alldone}{failed} = "Timed out, retrying";
						my %new = %$r;
						delete $new{alldone};
						$new{can_retry}++;
						$new{desc} = "RETRY$new{can_retry} $new{desc}";
						do_remote_job(%new);
						print STDERR "RETRYING REMOTE JOB $desc\n";
					} else {
						$r->{failure}->("Timed out waiting for job $desc on $host to connect to $listen_port for cookie $e");
					}
				}
				RPC::ToWorker::force_poll();
			},
		);

		# $listener->event->prio(1);

		$remote_killer = Proc::Parallel::RemoteKiller->new();
	}

	my $slavefh = new IO::Handle;
	my $parentfh = new IO::Handle;

	socketpair($slavefh, $parentfh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
		or die "socketpair: $!";
	my $pid = fork();
	my $slave;
	if ($pid) {
		# parent
		$parentfh->close();
		$slavefh->blocking(0);
		$slavefh->autoflush(1);
		$slave = IO::Event::Callback->new($slavefh,
			werror	=> sub {
				$params{failure}->("Could not write to stdin for $desc: $!");
				$alldone->{failed}->("Could not write to stdin for $desc: $!");
			},
			input	=> sub {
				my ($self, $ioe) = @_;
				while (<$ioe>) {
					if (/^SLAVE PID=(\d+)\n/) {
						$remote_killer->note($host, $1);
						$params{pid} = $1;
						$alldone->{slavepid} = $1;
						next;
					} elsif (/^compile finished\./) {
						$alldone->{compile_finished} = 1;
						next;
					}
					if ($params{output_handler}) {
						$params{output_handler}->($_);
					} else {
						print STDERR "$prefix SSH/ERROR: $_";
					}
				}
				RPC::ToWorker::force_poll();
			},
			eof	=> sub {
				my ($self, $ioe) = @_;
				$ioe->close();
				$params{output_handler}->("EOF on ssh ($desc)\n") if $debug_create;
			},
		);
		$params{output_handler}->("startup ($desc)\n") if $debug_create;
	} elsif (defined $pid) {
		# child
		$slavefh->close();
		$parentfh->autoflush(1);
		$parentfh->blocking(0);
		print $parentfh "Foo!\n" if $debug;
		open STDIN, "<&", \$parentfh or die "dup onto STDIN: $!";
		open STDOUT, ">&", \$parentfh or die "dup onto STDOUT: $!";
		open STDERR, ">&", \$parentfh or die "dup onto STDERR: $!";
		if (0 && $fqdnify{$host} eq $myfqdn) { # XXX why is this not reliable?
			exec $command
				or die "exec $command: $!";
		} else {
			exec 'ssh', $host, '-o', 'StrictHostKeyChecking=no', '-o', 'BatchMode=yes', $command,
				or do { 
					$params{failure}->("exec ssh $host $command: $!");
					return;
				};
		}
	} else {
		die "cannot fork: $!";
	}

	my $cookie;
	do {
		$cookie = "C".rand(100000000);
	} while defined $waiting{"$cookie MASTER"};

	$waiting{"$cookie MASTER"} = bless {
		slave		=> $slave,
		start_time	=> time,
		%params,
	}, 'RPC::ToWorker::Master';

	$waiting{"$cookie OUTPUT"} = bless {
		slave		=> $slave,
		start_time	=> time,
		%params,
	}, 'RPC::ToWorker::Output';

	my $stream = '';

	if ($params{stream_in} || $params{stream_out}) {
		$stream = eval_line_numbers(<<END_STREAM);
			my \$stream = new IO::Socket::INET (
				PeerAddr	=> '$myfqdn:$listen_port',
				Proto		=> 'tcp',
			);
			die "Could not connect to master at $myfqdn:$listen_port: \$!" unless \$stream;
			\$stream->autoflush(1);
			print \$stream "$cookie STREAM\\n"
				or die;
END_STREAM

		$waiting{"$cookie STREAM"} = bless {
			slave		=> $slave,
			start_time	=> time,
			%params,
		}, 'RPC::ToWorker::Stream';
	}

	my $pre = '';
	$pre .= "use $_; " for @$preload;

	my $p5lib = $ENV{PERL5LIB} || '';

	my $av0 = "slave for $myfqdn:$$ - $desc: ";

	print $slave eval_line_numbers(<<END_SLAVE0);
		\$0 = $q_perl{$av0} . 'starting';
		use strict;
		use warnings;
		BEGIN {
			print "SLAVE PID=\$\$\\n";
			chdir($q_perl{$chdir}) or die "cannot chdir to $chdir on $host: \$!";
			unshift(\@INC, split(':', $q_perl{$p5lib}));
		}
END_SLAVE0

	print $slave $prequel;
	print $slave "\n";
	print $slave eval_line_numbers(<<END_SLAVE1);
		use IO::Socket::INET;
		use Storable qw(freeze thaw);
		$pre
END_SLAVE1
	print $slave eval_line_numbers(<<END_SLAVE2);

		if ($debug) {
			open(DEBUG, ">&STDERR") or die "dup STDERR: $!";
			print STDERR "Dup to DEBUG should have worked\\n";
			select(DEBUG);
			\$| = 1;
			select(STDOUT);
			printf DEBUG "debug test %d\\n", __LINE__;
		}

		\$0 = $q_perl{$av0} . 'redirecting STDOUT';

		my \$output = new IO::Socket::INET (
			PeerAddr	=> '$myfqdn:$listen_port',
			Proto		=> 'tcp',
		);
		die "Could not connect to master at $myfqdn:$listen_port: \$!" unless \$output;
		\$output->autoflush(1);
		print \$output "$cookie OUTPUT\\n";

		if ($debug) {
			printf DEBUG "debug test %d\\n", __LINE__;
			print STDERR "Connected for Output\\n";
			printf DEBUG "debug test %d\\n", __LINE__;
			print "Output connected\\n";
			printf DEBUG "debug test %d\\n", __LINE__;
			print \$output "test foo\\n";
			printf DEBUG "debug test %d\\n", __LINE__;
		}

		open STDOUT, ">&", \$output or die "dup to STDOUT: \$!";
		select STDOUT;
		\$| = 1;

		if ($debug) {
			print STDERR "stderr test\\n";
			printf DEBUG "debug test %d\\n", __LINE__;
		}

		\$0 = $q_perl{$av0} . 'connecting STREAM';

		$stream

		\$0 = $q_perl{$av0} . 'setting up MASTER';

		my \$master = new IO::Socket::INET (
			PeerAddr	=> '$myfqdn:$listen_port',
			Proto		=> 'tcp',
		);
		die "Could not connect to master at $myfqdn:$listen_port: \$!" unless \$master;
		\$master->autoflush(1);
		printf DEBUG "debug test %d\\n", __LINE__ if $debug;
		print \$master "$cookie MASTER\\n"
			or die;
		printf DEBUG "debug test %d\\n", __LINE__ if $debug;

		\$0 = $q_perl{$av0} . 'looking for "go" from master';

		my \$go = <\$master>;

		chomp(\$go);
		exit 1 if \$go eq 'suicide';

		\$go =~ /go (\\d+)/;
		my \$amt = \$1;
		die unless \$amt;

		\$0 = $q_perl{$av0} . 'downloading initial data';

		my \$buf = '';

		while (length(\$buf) < \$amt) {
			read(\$master, \$buf, \$amt - length(\$buf), length(\$buf)) or die;
		}

		printf DEBUG "debug test %d\\n", __LINE__ if $debug;

		\$0 = $q_perl{$av0} . 'reconstituting initial data';

		my \$data = \${thaw(\$buf)};

		\$RPC::ToWorker::Callback::master =  # suppress used-once warning
		\$RPC::ToWorker::Callback::master = \$master;

		printf DEBUG "debug test %d\\n", __LINE__ if $debug;
END_SLAVE2
	print $slave eval_line_numbers(<<END_SLAVE3);

		\$0 = $q_perl{$av0} . 'RUNNING';
		my \@r;

		printf DEBUG "debug test %d\\n", __LINE__ if $debug;
		eval {
			sub slave_eval {
				$eval
			}
			\@r = slave_eval(\$data);
		};
		printf DEBUG "debug test %d\\n", __LINE__ if $debug;

		if (\$\@) {
			\$0 = $q_perl{$av0} . 'returning failure';
			print STDERR \$\@;
			my \$err = freeze(\\\$\@);
			printf \$master "DATA %d RETURN_ERROR\\n%s", length(\$err), \$err;
			# exit 1; hangs
			POSIX::_exit(1);
		}

		\$0 = $q_perl{$av0} . 'returning results';

		my \$ret = freeze(\\\@r);
		printf \$master "DATA %d RETURN_VALUES\\n%s", length(\$ret), \$ret;

		\$0 = $q_perl{$av0} . 'exiting';

		exit;

		BEGIN { print STDERR "compile finished.\\n" }
END_SLAVE3
	shutdown($slavefh, 1); # done writing
}

sub ie_connection
{
	my ($pkg, $ioe) = @_;
	print STDERR "# GOT CONNECTION\n" if $RPC::ToWorker::debug;
	my $newfh = $ioe->accept();
	# $newfh->event->prio(1);
	$forced_polling{refaddr($newfh)} = $newfh;
	weaken($forced_polling{refaddr($newfh)});
	RPC::ToWorker::force_poll();
}

sub ie_input
{
	my ($self, $ioe) = @_;
	my $cookie = <$ioe>;
	return unless $cookie;
	chomp($cookie);
	print STDERR "# GOT COOKIE $cookie\n" if $debug;
	unless ($waiting{$cookie}) {
		warn "Unknown cookie '$cookie'";
		next;
	}
	$ioe->handler($waiting{$cookie});
	# $ioe->event->prio(4);
	my $o = $waiting{$cookie};
	$o->{output_handler}->(sprintf("using fd %d for $cookie (%s)\n", $ioe->fileno, $o->{desc})) if $RPC::ToWorker::debug_create;
	$waiting{$cookie}->send_initial_data($ioe);
	delete $waiting{$cookie};
	RPC::ToWorker::force_poll();
}

sub ie_eof
{
	my ($self, $ioe) = @_;
	$ioe->close();
}


package RPC::ToWorker::Master;

#
# This is on the master
#

use strict;
use warnings;
use Storable qw(freeze thaw);
use Module::Load qw(load);

sub send_initial_data
{
	my ($self, $ioe) = @_;

	if ($self->{alldone}{retrying}) {
		print $ioe "suicide\n";
	} else {
		$self->{alldone}{master_go} = 1;

		my $id = freeze(\($self->{data} || undef));

		printf $ioe "go %d\n", length($id); # don't suicide

		print $ioe $id;
		print STDERR "# DATA SENT\n" if $RPC::ToWorker::debug;
	}
}

sub ie_input
{
	my ($self, $ioe, $ibr) = @_;
	$self->{output_handler}->("control socket input ready ($self->{desc})\n") if $RPC::ToWorker::debug_create;
	while ($$ibr =~ /\A(DATA (\d+) ([^\n]+)\n)/ && length($$ibr) - length($1) >= $2) {
		my ($header, $dsize, $control) = ($1, $2, $3);
		my $data = thaw(substr($$ibr, length($header), $dsize));
		substr($$ibr, 0, length($header) + $dsize, '');
		if ($control =~ /^RETURN_VALUES$/) {
			$self->{output_handler}->("return values sent - $dsize ($self->{desc})\n") if $RPC::ToWorker::debug_create;
			eval {
				$self->{when_done}->(@$data);
			};
			$self->{failure}->("when done for $self->{desc}: $@") if $@;
			$self->{return_values_sent} = 1;
			$ioe->close();
		} elsif ($control =~ /^RETURN_ERROR$/) {
			my $error = $$data;
			$self->{failure}->("SLAVE FAILURE: $error");
			$self->{alldone}{failured} = "SLAVE FAILURE: $error";
			$self->{output_handler}->("return error ($self->{desc})\n") if $RPC::ToWorker::debug_create;
		} elsif ($control =~ /^CALL (\S+) with (.*?) after loading (.*)/) {
			my ($func, $with, $mods) = ($1, $2, $3);
			for my $mod (split(' ', $mods)) {
				load $mod;
			}
			for my $item (split(' ',$with)) {
				push(@$data, $item);
				push(@$data, $self->{local_data}{$item});
			}
			my @ret;
			eval {
				no strict 'refs';
				@ret = &{$func}(@$data);
			};
			$self->{failure}->("call to $func on behalf of $self->{desc}: $@") if $@;
			my $ret = freeze(\@ret);
			printf $ioe "DATA %d DONE_RESPONSE\n%s", length($ret), $ret or die;
		} else {
			$self->{failure}->("SLAVE FAILURE: could not parse input from slave");
			$self->{alldone}{failured} = "SLAVE FAILURE: could not parse input from slave";
			$self->{output_handler}->("return parse error ($self->{desc})\n") if $RPC::ToWorker::debug_create;
		}
	}
	RPC::ToWorker::force_poll();
}

sub ie_werror
{
	my ($self, $ioe) = @_;
	return if $self->{alldone}{retrying};
	IO::Event->timer(
		after	=> 5,
		cb	=> sub { $self->{failure}->("Could not write to control socket for: $self->{desc}") },
	);
	print STDERR "Failed: Could not write to control socket for job: $self->{desc}, will suicide soon, after queued output has chance to print\n";
	$self->{alldone}{failured} = "Could not write to control socket for job: $self->{desc}";
	$self->{output_handler}->("Write error on control socket ($self->{desc})\n") if $RPC::ToWorker::debug_create;
}

sub ie_eof
{
	my ($self, $ioe) = @_;

	$self->{output_handler}->("EOF on control socket ($self->{desc})\n") if $RPC::ToWorker::debug_create;
	$ioe->close();

	return if $self->{return_values_sent};
	return if $self->{alldone}{retrying};

	IO::Event->timer(
		after	=> 5,
		cb	=> sub { $self->{failure}->("No return values from remote job: $self->{desc}") },
	);
	print STDERR "Failed: no return values from remote job: $self->{desc}, will suicide soon, after queued output has chance to print\n";
	$self->{alldone}{failured} = "No return values from remote job: $self->{desc}";
}

package RPC::ToWorker::Output;

use strict;
use warnings;

sub send_initial_data 
{
	my ($self, $ioe) = @_;
	shutdown($ioe->filehandle(), 1); # we don't write to this one
	# $ioe->event->prio(6);
}

sub ie_input
{
	my ($self, $ioe) = @_;
	while (<$ioe>) {
		next if /ssh_exchange_identification: Connection closed by remote host/;
		if ($self->{output_handler}) {
			$self->{output_handler}->($_) 
		} else {
			print STDERR "$self->{prefix} OUTPUT: $_";
		}
	}
	RPC::ToWorker::force_poll();
}

sub ie_eof
{
	my ($self, $ioe) = @_;
	$ioe->close();
	$self->{output_handler}->("EOF on output socket ($self->{desc})\n") if $RPC::ToWorker::debug_create;
}

package RPC::ToWorker::Stream;

use strict;
use warnings;
use Storable qw(freeze thaw);

sub send_initial_data
{
	my ($self, $ioe) = @_;
	$self->{stream_werror} ||= sub {
		my ($self, $ioe) = @_;
		IO::Event::unloop_all();
		die "Write error sending data to $self->{desc}: $!";
	};
	for my $h (@IO::Event::Callback::handlers, 'setup') {
		$self->{"stream_$h"} ||= sub {};
	}
	$self->{'stream_setup'}->($self, $ioe);
	# $ioe->event->prio(5);
}

sub ie_input		{ $_[0]->{'stream_input'}->(@_)		};
sub ie_connection	{ $_[0]->{'stream_connection'}->(@_)	};
sub ie_read_ready	{ $_[0]->{'stream_read_ready'}->(@_)	};
sub ie_werror		{ $_[0]->{'stream_werror'}->(@_)	};
sub ie_eof		{ $_[0]->{'stream_eof'}->(@_)		};
sub ie_output		{ $_[0]->{'stream_output'}->(@_)	};
sub ie_outputdone	{ $_[0]->{'stream_outputdone'}->(@_)	};
sub ie_connected	{ $_[0]->{'stream_connected'}->(@_)	};
sub ie_connect_failed	{ $_[0]->{'stream_connect_failed'}->(@_)};
sub ie_died		{ $_[0]->{'stream_died'}->(@_)		};
sub ie_timer		{ $_[0]->{'stream_timer'}->(@_)		};
sub ie_exception	{ $_[0]->{'stream_exception'}->(@_)	};
sub ie_outputoverflow	{ $_[0]->{'stream_outputoverflow'}->(@_)};

package RPC::ToWorker::AllDone;

use strict;
use warnings;

sub DESTROY
{
	my ($self) = @_;
	$self->{failure}->($self->{failed}) if $self->{failed} && ! $self->{retrying};
	$RPC::ToWorker::remote_killer->forget($self->{host}, $self->{slavepid})
		if $self->{slavepid};
	$self->{all_done}->() if $self->{all_done};
	$RPC::ToWorker::remote_killer->forget($self->{host}, $self->{pid})
		if $self->{pid};
	RPC::ToWorker::force_poll();
	$self->{output_handler}->("Alldone on ($self->{desc})\n") if $RPC::ToWorker::debug_create;
}

1;

__END__

=head1 NAME

RPC::ToWorker - invoke remote perl functions asynchronously on remote systems

=head1 SYNOPSIS

 use RPC::ToWorker;

 do_remote_job(
	prefix		=> '#output prefix',
	chdir		=> '/some/directory',
	host		=> 'some.host.name',
	data		=> $data_to_send,
	preload		=> [qw(List::Of Required::Modules )],
	desc		=> 'remote job description',
	eval		=> 'my ($data) = @_; code_to_run(); return(@values)',
	when_done	=> sub { my (@slave_return_values) = @_; },
	all_done	=> \&callback_for_slave_process_is_finished,
	error_handler	=> \&callback_for_STDERR_output_from_slave,
	output_handler	=> \&callback_for_STDOUT_output_from_slave,
 );

 IO::Event::loop;

=head1 DESCRIPTION

RPC::ToWorker provides a way to invoke a perl function
on a remote system.   It starts the remote perl process, passes
data to it, and runs arbitrary code.   It does this all with 
asynchronous IO (using L<IO::Event>) so that multiple
processes can run at the same time.

The slave job on the remote system can also invoke functions
in the master process using C<master_call> in 
L<RPC::ToWorker::Callback>.

=head1 PARAMETERS

=over

=item host

B<Required>.
The remote hostname.

=item eval

B<Required>.
Code to eval on the remote host.  Return values will be passed to
C<when_done> code reference.  One argument will arrive in C<@_>: 
the C<data> element from below.

=item when_done

Code reference to invoke with the return values from the C<eval>.

=item data

Data reference to pass to the remote process.  It will be 
marshalled with Storable.  This reference will be passed to the
C<eval> code as is (arrays will not be expanded).

=item chdir

Directory to C<chdir()> to before doing anything else.

=item desc

Text (short) description of the remote job for error messages.

=item prefix

String to prefix each line of output from the slave with.
Defaults to C<host:>.

=item preload

Modules to load on the remote system, a list.

=item prequel

Code to eval prior to the main eval.  Must not C<return>.  This
is a pre-amble.  Local variables can be delcared.  Modules can
be loaded.   The main eval is inside a block.  This is not.

=item error_handler($ioe)

B<This is currently disabled>
Code reference to call when there is STDERR output from the 
slave process.  The default handler prints the output to 
STDOUT prefixed with C<prefix>.  
C<$ioe> is an L<IO::Event> object so you can loop over it
like a normal file descriptor.

=item output_handler($ioe)

Code reference to call when there is STDOUT output from the 
slave process.  The default handler prints the output to 
STDOUT prefixed with C<prefix>.
C<$ioe> is an L<IO::Event> object so you can loop over it
like a normal file descriptor.

=item on_failure

Code reference to invoke if the slave process failes to run.
It may be invoked multiple times for the same slave.

=item all_done

Code reference to invoke when the slave process is fully 
shut down.

=item local_data

A hash of data that can be made available to 
C<master_call()> invocations.  See
L<RPC::ToWorker::Callback>.

=item can_retry

Can this job be re-attempted?   Defaults to 1.

=back

=head1 SEE ALSO

To make callbacks to the master from the worker slave,
use C<RPC::ToWorker::Callback>.

This module expects to exist with an L<IO::Event> select loop.
This isn't much of a limitation since L<IO::Event::Any> layers
over L<AnyEvent>.

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

