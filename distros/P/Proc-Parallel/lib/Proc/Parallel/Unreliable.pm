
package Proc::Parallel::Unreliable;

use strict;
use warnings;
use IO::Event qw(emulate_Event);
use IO::Handle;
require Exporter;
use Hash::Util qw(lock_keys);
use POSIX ":sys_wait_h";
use Scalar::Util qw(refaddr);
use File::Slurp;

our @ISA = qw(Exporter);
our @EXPORT = qw(run_subprocess);

sub run_subprocess
{
	my (%params) = @_;

	my $input		= $params{input}	|| die;
	my $ouptut		= $params{output}	|| die;
	my $cb			= $params{cb} 		|| die;
	my $count		= $params{count} 	||= 1;
	my $timeout		= defined($params{timeout}) ? $params{timeout} : 60;
	my $input_id		= $params{input_id}	||= sub { die };
	my $output_id		= $params{output_id}	||= sub { die };
	my $input_hlines	= $params{input_hlines} ||= 0;
	my $output_hlines	= $params{output_hlines}||= 0;
	my $items		= $params{items}	||= 1;
	my $track_items		= $params{track_items}	||= 0;
	my $debug		= $params{debug}	||= 0;

	$params{hlines_done} = 0;

	local($SIG{USR1}) = sub { $debug++; };
	local($SIG{USR2}) = sub { $debug = 0 };

	my $self = bless \%params;

	$self->{av0} = $0;
	local($0) = "$0: control wrapper";
	local($SIG{PIPE}) = 'IGNORE';

	#
	# Capture the input header
	#
	my @hlines;
	for (1..$input_hlines) {
		push(@hlines, scalar(<$input>));
		print STDERR "CAPTURE HEADER: $hlines[-1]" if $debug > 5;
	}

	$self->{hlines} = \@hlines;
	$self->{alldone} = 0;
	$self->{timeout} = $timeout;
	$self->{children} = {};
	$self->{input_buffer} = [];
	$self->{attempted} = 0;
	$self->{completed} = 0;
	$self->{input_items} = 0;

	$self->{input_handler} = Proc::Parallel::Unreliable::Input->new($self);

	my $last_complete = 0;

	$self->{timer} = IO::Event->timer(
		interval	=> $timeout / 5,
		cb		=> sub {
			print STDERR "[cntrl] Timer! alldone=$self->{alldone}\n" if $debug > 3;
			for my $child (values %{$self->{children}}) {
				$child->check_health;
				$child->print_status if $debug > 4 || ($self->{alldone} && $debug);
			}
			use POSIX ":sys_wait_h";
			my $k;
			do { $k = waitpid(-1, WNOHANG) } while $k > 0;


			my $pending = 0;
			my $dups_waiting = 0;
			my $completed = 0;
			for my $child (values %{$self->{children}}) {
				$pending += keys %{$child->{pending}};
				$dups_waiting += keys %{$child->{duplicate_items}};
				$completed += $child->{completed};
			}
			$0 = sprintf("%s: control wrapper: %d input %d completed %d pending %d dups waiting, %d finished recently",
				$self->{av0},
				$self->{input_items},
				$completed,
				$pending,
				$dups_waiting,
				$completed - $last_complete);
			$last_complete = $completed;
		},
	);

	lock_keys(%$self);

	Proc::Parallel::Unreliable::Child->new($self) for 1..$self->{count};

	IO::Event::loop;

	if ($self->{attempted}) {
		printf STDERR "Processed %d items, dropped %d items (%.1f%%)\n",
			$self->{completed},
			$self->{attempted}-$self->{completed},
			($self->{attempted}-$self->{completed})/$self->{attempted}*100;
	}
}


sub send_data
{
	my ($self, $one_child) = @_;
	my $input_buffer = $self->{input_buffer};

	printf STDERR "[cntrl] send_data %d\n", scalar(@$input_buffer) if $self->{debug} > 4;

	CHILD:
	for my $child ($one_child ? ($one_child) : values %{$self->{children}}) {
		while ($child->can_send && @$input_buffer) {
			$child->send(pop(@$input_buffer));
			last CHILD unless @$input_buffer;
		}
	}
	$self->{input_handler}->readevents() if $one_child && ! $self->{alldone};
	if ($self->{alldone} && ! @$input_buffer) {
		for my $child (values %{$self->{children}}) {
			$child->no_more_input;
		}
	}
}

sub dead_child
{
	my ($self, $child, %data) = @_;
	my $debug = $self->{debug};

	$self->{attempted} += $data{attempted} || 0;
	$self->{completed} += $data{completed} || 0;

	my $input_buffer = $self->{input_buffer};
	print STDERR "[$child->{pid}] dead_child\n" if $debug > 4;
	printf STDERR "[cntrl] num children = %d\n", scalar(keys %{$self->{children}}) if $debug > 6;
	delete $self->{children}{refaddr($child)};
	printf STDERR "[cntrl] num children = %d\n", scalar(keys %{$self->{children}}) if $debug > 4;
	$self->write_pid_file();
	if ($self->{alldone} && ! @$input_buffer) {
		if (keys %{$self->{children}}) {
			print STDERR "[cntrl] waiting for children to finish\n" if $debug > 4;
		} else {
			print STDERR "[cntrl] UNLOOP!\n" if $debug > 1;
			IO::Event::unloop_all;
		}
	} elsif (keys %{$self->{children}} < $self->{count}) {
		print STDERR "[cntrl] start another kid\n" if $debug > 1;
		Proc::Parallel::Unreliable::Child->new($self);
	}
}

sub write_pid_file
{
	my $self = shift;
	return unless $self->{pidfile};
	overwrite_file($self->{pidfile}, join("\n", $$, map { $_->{pid} } values %{$self->{children}}), "\n");
}

package Proc::Parallel::Unreliable::Input;

use strict;
use warnings;
use Scalar::Util qw(weaken);
use Hash::Util qw(lock_keys);

sub new 
{
	my ($pkg, $control) = @_;

	$control->{input}->blocking(0);

	my $self = bless {
		control		=> $control,
		input_buffer	=> $control->{input_buffer},
		input_max	=> ($control->{items} || 1) * ($control->{count} || 1) * 2,
		debug		=> $control->{debug},
	};

	$self->{ioe} = IO::Event->new($control->{input}, $self);

	lock_keys(%$self);

	return $self;
}

sub ie_input
{
	my ($self, $ioe, $ibr) = @_;
	return unless length($$ibr);
	my $control = $self->{control};
	my $input_buffer = $self->{input_buffer};

	for(;;) {
		my $input = <$ioe>;
		last unless $input;
		push(@$input_buffer, \$input);
		$control->{input_items}++;
		print STDERR "[cntrl] input read\n" if $self->{debug} > 8;
	}
	$control->send_data();
	$self->readevents;
}

sub readevents
{
	my ($self) = @_;
	my $input_buffer = $self->{input_buffer};
	$self->{ioe}->readevents(@$input_buffer <= $self->{input_max});
	printf STDERR "[cntrl] readevents = %s\n", (@$input_buffer <= $self->{input_max}) ? 'On' : 'Off' if $self->{debug} > 7;
}

sub ie_eof
{
	my ($self, $ioe, $ibr) = @_;
	my $control = $self->{control};
	$control->{alldone} = 1;
	$self->ie_input($ioe, $ibr);
	my $debug = $self->{debug};
	print STDERR "[cntrl] NO MORE INPUT\n" if $debug;
	# $ioe->close();
	$ioe->readevents(0);
	weaken($self->{control});
}

package Proc::Parallel::Unreliable::Child;

use strict;
use warnings;
use Time::HiRes qw(time);
use Hash::Util qw(lock_keys);
use Scalar::Util qw(weaken refaddr);
use Socket;
use List::Util qw(min);

sub new
{
	my ($pkg, $control) = @_;

	my $childfh = new IO::Handle;
	my $parentfh = new IO::Handle;

	socketpair($childfh, $parentfh, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
		or die "socketpair: $!";

	my $pid = fork();
	if (! defined($pid)) {
		die "cannot fork: $!";
	} elsif ($pid == 0) {

		# child

		$0 = "$control->{av0}: worker";
		$control->{timer}->cancel();
		IO::Event::unloop_all;
		$childfh->close();
		$parentfh->autoflush(1);
		close(STDIN);
		close(STDOUT);
		open STDIN, "<&", \$parentfh or die "dup onto STDIN: $!";
		open STDOUT, ">&", \$parentfh or die "dup onto STDOUT: $!";
		select($parentfh);
		print STDERR "[$$] Invoking callback now\n" if $control->{debug};
		$control->{cb}->($parentfh, $parentfh);
		print STDERR "[$$] callback finished\n" if $control->{debug};
		POSIX::_exit(0);
	}

	# parent

	$parentfh->close();
	$childfh->blocking(0);
	$childfh->autoflush(1);

	print STDERR "PRINT TO CHILD: @{$control->{hlines}}\n" if $control->{debug} > 7 && @{$control->{hlines}};
	print $childfh @{$control->{hlines}} if @{$control->{hlines}};

	my $header = $control->{output_hlines} && ! $control->{hlines_done};

	my $self = bless {
		pid		=> $pid,
		inflight	=> 0,
		pending		=> {},
		pending_times	=> {},
		pending_order	=> {},
		control		=> $control,
		overflow	=> 0,
		last_output	=> 0,
		last_input	=> time,
		track_items	=> $control->{track_items},
		shutdown	=> 0,
		header		=> $header,
		output_hlines	=> $control->{output_hlines},
		debug		=> $control->{debug},
		duplicate_items	=> {},
		closing_down	=> 0,
		seqno		=> 0,
		completed	=> 0,
		timebomb	=> 0,
	};

	print STDERR "[$$] Started slave $self->{pid}\n";

	$self->{ioe} = IO::Event->new($childfh, $self);

	lock_keys(%$self);

	printf STDERR "[$pid] Looking for header: %s\n", $header ? 'Yes' : 'No' if $control->{debug} > 5;

	$control->{children}{refaddr($self)} = $self;

	$control->write_pid_file();

	$control->send_data($self);

	return $self;
};

sub can_send
{
	my ($self) = @_;
	return 0 if $self->{shutdown};
	return 0 if $self->{closing_down};
	return 0 if $self->{overflow};
	return 0 if $self->{track_items} && $self->{inflight} >= $self->{control}{items};

	#
	# Since recent output will case check_health to pass, we don't want to send any output 
	# if we're not sure we're healthy
	#
	return 0 if (! $self->{track_items}) && $self->{last_output} > $self->{last_input} + $self->{control}{timeout};

	my $if = $self->{track_items} ? "($self->{inflight} in flight)" : "(not overflowed)";
	print STDERR "[$self->{pid}] ready to send $if\n" if $self->{debug} > 5;
	return 1;
}

sub send
{
	my ($self, $iref) = @_;
	my $ioe = $self->{ioe};
	my $debug = $self->{debug};
	if ($self->{track_items}) {
		my $id = $self->{control}{input_id}->($iref);
		print STDERR "[$self->{pid}] SEND $id\n" if $debug > 3;
		if (defined($id)) {
			if ($self->{pending}{$id}) {
				print STDERR "[$self->{pid}] Deferring processing of duplicate item $id\n";
				$self->{duplicate_items}{$id} = []
					unless $self->{duplicate_items}{$id};
				push(@{$self->{duplicate_items}{$id}}, $iref);
				return;
			} else {
				$self->{inflight}++;
				$self->{pending}{$id} = $iref;
				$self->{pending_times}{$id} = time;
				$self->{pending_order}{$id} = ++$self->{seqno};
			}
		} else {
			warn "Unable to determine item id, turning off item tracking";
			delete $self->{track_items};
		}
	} elsif ($debug > 5) {
		print STDERR "[$self->{pid}] sending\n";
	}

	$self->{last_output} = time;
	unless (print $ioe $$iref) {
		warn "[$self->{pid}] write failed: $!";
		$self->ie_werror($ioe);
	}
}

sub no_more_input
{
	my ($self) = @_;
	if (keys %{$self->{duplicate_items}} && $self->{track_items}) {
		print STDERR "[$self->{pid}] ignoring shutdown for the time being\n" if $self->{debug} > 3;
	} else {
		return if $self->{shutdown}++;
		print STDERR "[$self->{pid}] shutting down\n" if $self->{debug} > 3;
		$self->{ioe}->shutdown(1);
		$self->{timebomb} = time unless $self->{timebomb};
	}
}

sub ie_input
{
	my ($self, $ioe, $ibr) = @_;
	my $control = $self->{control};
	my $debug = $self->{debug};
	if ($self->{header} && ! $control->{hlines_done}) {
		# do we have enough header?
		my $cnt = $$ibr =~ tr/\n/\n/;
		if ($cnt < $control->{output_hlines}) {
			print STDERR "[$self->{pid}] Don't have enough header yet (%d vs %d)\n", $cnt, $control->{output_hlines} if $debug > 2;
			$control->send_data($self) if $self->can_send;
			return;
		}
		print STDERR "[$self->{pid}] we have enough lines for a header\n" if $debug > 5;
	}
	while (<$ioe>) {
		print STDERR "[$self->{pid}] READ $_" if $debug > 8;
		if ($self->{output_hlines}) {
			$self->{output_hlines}--;
			printf STDERR "[$self->{pid}] FOUND HEADER lines remaining: %d, want header: %s\n", $self->{output_hlines}, $control->{hlines_done} ? 'Y' : 'N' if $debug > 4;
			next if $control->{hlines_done};
			# because of the test up above, and because we're single-threaded, we know
			# that we will be able to output the entire header w/o anyone else running.
			$control->{output}->($_);
			next unless $self->{output_hlines} == 0;
			$control->{hlines_done} = $$;
			next;
		}
		if ($self->{track_items}) {
			$self->{inflight}--;
			my $id = $control->{output_id}->(\$_);
			print STDERR "[$self->{pid}] GOT $id\n" if $debug > 3;
			delete $self->{pending}{$id}
				or warn "no pending '$id' to delete";
			delete $self->{pending_times}{$id};
			my $seq = delete $self->{pending_order}{$id};
			for my $i (grep { $self->{pending_order}{$_} < $seq } keys %{$self->{pending_order}}) {
				print STDERR "[$self->{pid}] No results for $i\n";
				delete $self->{pending}{$i};
				delete $self->{pending_order}{$i};
				delete $self->{pending_times}{$i};
				delete $self->{duplicate_items}{$i};   # don't retry dups
			}
			if ($self->{duplicate_items}{$id}) {
				print STDERR "[$self->{pid}] Requeuing duplicate item $id\n";
				push(@{$control->{input_buffer}}, @{$self->{duplicate_items}{$id}});
				delete $self->{duplicate_items}{$id};
			}
			$self->{completed}++;
		}
		$control->{output}->($_);
		$self->{last_input} = time;
	}
	$control->send_data($self) if $self->can_send;
}

sub ie_eof
{
	my ($self, $ioe, $ibr) = @_;
	$self->ie_input($ioe, $ibr);
	my $debug = $self->{debug};
	print STDERR "[$self->{pid}] EOF\n" if $debug > 2;
	$self->closedown('EOF');
}

sub print_status
{
	my ($self) = @_;
	printf STDERR "[%d] Status.  track_items=%s inflight=%d pending=%d overflow=%s shutdown=%d closing_down=%d duplicates=%d last_output=%d oldest_item=%d last_input=%d timebomb=%d\n",
		$self->{pid},
		$self->{track_items},
		$self->{inflight},
		scalar(keys %{$self->{pending}}),
		$self->{overflow},
		$self->{shutdown},
		$self->{closing_down},
		scalar(keys %{$self->{duplicate_items}}),
		time - $self->{last_output},
		time - min(time, values %{$self->{pending_times}}),
		time - $self->{last_input},
		($self->{timebomb} ? time - $self->{timebomb} : 0);
}

#
# Look for hung workers
#	last_output is the time something was sent to the worker
#	last_input is the time something was received from the worker
#
sub check_health
{
	my ($self) = @_;
	my $control = $self->{control};
	my $debug = $self->{debug};

	#
	# An attempt to work around an odd race-condition hang.
	#
	if ($self->{timebomb} and time - $self->{timebomb} > $control->{timeout} * ($self->{control}{items} + 1)) {
		print STDERR "[$self->{pid}] FAILED HEALTH CHECK - timebomb\n" if $debug;
		$self->ie_werror;
		return;
	}

	#
	# We've never sent any output.  The master can shut us down at any time.
	#
	return unless $self->{last_output};

	#
	# We're already in the process of closing down.  The master already knows and
	# wont wait for us.
	#
	return if $self->{closing_down};

	#
	# We've recevied input recently, obviously nothing is wrong.
	#
	return if time - $self->{last_input} < $control->{timeout};

	if ($self->{track_items}) {
		#
		# We're tracking individual items.  We're in trouble only
		# if a particular item is overdue.
		#
		my $bad;
		for my $i (values %{$self->{pending_times}}) {
			next if time - $i < $control->{timeout};
			$bad = $i;
		}
		return unless $bad;
	} else {
		#
		# We aren't tracking items.   Since we had input more recently
		# than we sent something, we're probably still okay.  
		#
		return if $self->{last_input} > $self->{last_output};

		#
		# We only did some output recently, so maybe we haven't had any
		# input yet?  can_send() prevents us from sending and sending
		# even though we haven't had any input.
		#
		return if time - $self->{last_output} < $control->{timeout};
	}
	print STDERR "[$self->{pid}] FAILED HEALTH CHECK\n";
	$self->ie_werror;
}

sub requeue_outstanding
{
	my ($self, $reason) = @_;
	my $control = $self->{control};
	if ($self->{track_items}) {
		my $pending = $self->{pending};
		my $porder = $self->{pending_order};
		my @ilist = sort { $porder->{$a} <=> $porder->{$b} } keys %$pending;
		my $bad = shift(@ilist); 
		warn "[$self->{pid}] Slave process failed at $reason, probably working on '$bad'\n" if $bad;
		push(@{$control->{input_buffer}}, map { $pending->{$_} } @ilist);
	}
	$self->{pending} = {};
	$self->{pending_times} = {};
	$self->{pending_order} = {};
}

sub closedown
{
	my ($self, $reason) = @_;
	my $control = $self->{control};
	$self->requeue_outstanding($reason);
	$control->dead_child($self, attempted => $self->{seqno}, completed => $self->{completed}) if $control;
	return if $self->{closing_down}++;
	$self->{ioe}->close;
	eval { weaken($self->{control}); };
}

sub ie_werror
{
	my ($self) = @_;
	$self->closedown('write error');
	if (kill(0, $self->{pid})) {
		print STDERR "Killing child $self->{pid}\n";
		if (kill(15, $self->{pid})) {
			sleep(1);
			kill(9, $self->{pid});
		}
	}
}

sub ie_outputoverflow
{
	my ($self, $ioe, $overflow) = @_;
	print STDERR "[$self->{pid}] overflow=$overflow\n" if $self->{debug} > 4;
	$self->{overflow} = $overflow;
}

1;

__END__

=head1 NAME

Proc::Parallel::Unreliable - maintain a pool of unreliable slave processes

=head1 SYNOPSIS

 use Proc::Parallel::Unreliable;

 run_subprocess(
	input		=> $input_filehandle,
	output		=> $output_callback_function,
	cb		=> $slave_process_start_function,
	count		=> $number_of_slaves_to_run,
	timeout		=> $maximum_time_to_process_a_line,
	input_id	=> $callback_to_identify_input,
	input_hlines	=> $number_of_header_lines_in_input_stream,
	output_hlines	=> $number_of_header_lines_in_output_stream,
	output_id	=> $callback_to_identify_output,
	items		=> $number_of_buffer_lines_per_slave,
	track_items	=> $identify_items_flag,
	debug		=> $debug_level,
	pidfile		=> $process_id_file_to_update,
 );

=head1 DESCRIPTION

This module deals with a particular situation: needing to run code
that may crash or hang while processing a stream of data.  

It reads input, farms the input out to one or more slave process, 
collects the output from the slave processes, and writes a single
stream of output.

Each line of input must be self-contained because it can be randomly sent
to any of the slaves.

It has two modes: tracking items, or not tracking items.  When it tracks
items, it uses the C<input_id> callback to identify the input items
and the C<output_id> callback to identify the results it gets back from
the slaves.   When tracking items, the slave processes must produce output
for each input item: they'll be killed off if they don't.

When not tracking items, output is sent to the slave processes until the
buffers fill up.  It's not as elegant.

If the input stream or the output stream has headers, the input stream headers
will be reproduced for each slave and the output stream headers will be 
suppresssed except for one slave.  Use the C<input_hlines> and C<output_hlines>
parameters for this.

Output is written with a callbac: C<output>.

The process id file, C<pidfile> will be updated to show the current set of 
processes.

=head1 EXAMPLE

 run_subprocess(
	output		=> sub {
				print $output $o;
			},
	input		=> $input,
	cb		=> sub {
				my ($my_input_fd, $my_output_fd) = @_;
				run_transformation($my_input_fd,$my_output_fd);
			},
	count		=> 3,
	timeout		=> 60,
	input_id	=> sub {
				my ($iref) = @_;
				$$iref =~ /^(\d+)/
				return $1;
			},
	input_hlines	=> 0,
	output_hlines	=> 1,
	output_id	=> sub {
				my ($oref) = @_;
				$$iref =~ /^(\d+)/
				return $1;
			},
	items		=> 4,
	track_items	=> 1,
	debug		=> $debug,
	pidfile		=> "/var/run/myprocess.pid",
 );

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

