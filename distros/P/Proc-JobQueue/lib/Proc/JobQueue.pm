
package Proc::JobQueue;

use strict;
use warnings;

use Time::HiRes qw(sleep);
use Sys::Hostname;
use Carp qw(confess);
use Hash::Util qw(lock_keys unlock_keys);
use Time::HiRes qw(time);
use Module::Load;
use Object::Dependency;
require Exporter;

our $VERSION = 0.903;
our $debug ||= 0;
our $status_frequency ||= 2;
our $host_canonicalizer ||= 'File::Slurp::Remote::CanonicalHostnames';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(is_remote_host canonicalize my_hostname);

sub configure
{
	my ($queue, %params) = shift;
	@$queue{keys %params} = values %params;
}

sub addhost
{
	my ($queue, $host, %params) = @_;
	my $hr;
	if ($hr = $queue->{status}{$host}) {
		@$hr{keys %params} = values %params;
	} else {
		$hr = $queue->{status}{$host} = {
			name		=> $host,
			jobs_per_host	=> $queue->{jobs_per_host},
			in_startmore	=> 0,
			%params,
			running		=> {},
			queue		=> {},
		};
	}
	$queue->set_readiness($host);
}

sub set_readiness
{
	my ($queue, $host) = @_;
	my $hr = $queue->{status}{$host};
	if ($hr->{jobs_per_host} and $hr->{jobs_per_host} > keys %{$hr->{running}}) {
		$queue->{ready_hosts}{$host} = $hr;
	} elsif (! keys %{$hr->{running}}) {
		$queue->{ready_hosts}{$host} = $hr;
	} else {
		delete $queue->{ready_hosts}{$host};
	}
}

sub new
{
	my ($pkg, %params) = @_;
	my $queue = bless {
		dependency_graph	=> undef,
		startmore_in_progress	=> undef,
		host_overload		=> 120,
		host_is_over		=> 0,
		jobnum			=> 1000,
		jobs_per_host		=> 4,
		queue			=> {},
		status			=> {},
		ready_hosts		=> {},
		hold_all		=> 0,
		hosts			=> [ my_hostname() ],
		%params,
	}, $pkg;
	$queue->addhost($_) for @{$queue->{hosts}};
	lock_keys(%$queue);
	return $queue;
}

sub hold
{
	my ($self, $new) = @_;
	$self->{hold_all} = $new if defined $new;
	return $self->{hold_all};
}

sub add
{
	my ($queue, $job, $host) = @_;
	confess "$job not a ref" unless ref $job;
	confess "$job is not a job" unless $job->isa('Proc::JobQueue::Job');

	$job->jobnum($queue->{jobnum}++)
		unless $job->jobnum;
	my $jobnum = $job->jobnum();

	print STDERR "Adding $jobnum - ".ref($job)." to worklist\n" if $debug > 2;
	my $q;
	if ($host) {
		confess "no $host" unless $queue->{status}{$host};
		$q = $queue->{status}{$host}{queue};
	} else {
		$q = $queue->{queue};
	}

	$q->{$jobnum} = $job;

	$job->{dependency_graph} = $queue->{dependency_graph}; # TODO: do this with a method

	$job->queue($queue);
	$queue->startmore;
}

# this looks at the dependency queue.  startmore_jobs looks at the 
# at the jobs queue.
sub startmore
{
	my ($job_queue) = shift;

	if ($job_queue->{startmore_in_progress}) {
		print STDERR "Re-entry to startmore prevented\n" if $debug;
		$job_queue->{startmore_in_progress}++;
		return 0;
	}
	$job_queue->{startmore_in_progress} = 2;

	my $dependency_graph = $job_queue->{dependency_graph};

	my $stuff_started = 0;

	my $jq_done;

	print STDERR "looking for more depenency graph items to queue up\n" if $debug;
	eval {
		$job_queue->checkjobs();

		while ($job_queue->{startmore_in_progress} > 1) {
			$job_queue->{startmore_in_progress} = 1;
			if ($dependency_graph) {
				while (my @runnable = $dependency_graph->independent(lock => 1)) {
					$stuff_started++;
					for my $task (@runnable) {
						print "Queuing $task->{desc}\n" if $debug;
						if ($task->can('run_dependency_task')) {
							$job_queue->{startmore_in_progress}++ if $task->run_dependency_task($dependency_graph);
						} elsif ($task->isa('Proc::JobQueue::Job')) {
							$job_queue->add($task, $task->{force_host});
						} else {
							die "don't know how to handle $task";
						}
					}
				}
			}

			$jq_done = $job_queue->startmore_jobs();

			redo if $job_queue->{startmore_in_progress} > 1;
		}
	};
	if ($@) {
		$job_queue->suicide();
	};

	$job_queue->{startmore_in_progress} = 0;

	return $jq_done unless $dependency_graph;

	if ($jq_done && $dependency_graph->alldone) {
		print STDERR "Nothing more to do\n";
		$job_queue->unloop();
		return 1;
	} elsif ($jq_done && ! $stuff_started) {
		if (keys %{$dependency_graph->{stuck}}) {
			print STDERR "All runnable jobs are done, remaining dependencies are stuck:\n";
			for my $o (values %{$dependency_graph->{stuck}}) {
				printf "\t%s\n", $dependency_graph->desc($o);
			}
			$job_queue->unloop();
			return 1;
		} else {
			print STDERR "Job queue is empty, but dependency graph doesn't think there is any work to be done!\n";
			$dependency_graph->dump_graph();
		}
	}
	return 0;
}

sub startmore_jobs
{
	my ($queue) = @_;
	return 0 if $queue->{hold_all};
	print "# Looking to start more\n" if $debug > 8;
	confess "no hosts added" unless keys %{$queue->{status}};
	my $stuff = 0;
	my $new_host_is_over = 0;
	while(1) {
		my $redo = 0;
		HOST:
		for my $host (keys %{$queue->{ready_hosts}}) {
			print STDERR "# checking $host to maybe start more jobs\n" if $debug > 3;
			my $hr = $queue->{ready_hosts}{$host};
			JOB:
			while ((! $hr->{jobs_per_host} && ! keys %{$hr->{running}}) || $hr->{jobs_per_host} > (keys %{$hr->{running}} || 0)) {
				print STDERR "# there is room for more on $host\n" if $debug > 4;
				$new_host_is_over++
					if keys(%{$hr->{queue}}) > $queue->{host_overload};
				my @q;
				push (@q, $hr->{queue});
				push (@q, $queue->{queue})
					if $hr->{jobs_per_host} && ! $queue->{host_is_over};
				for my $q (@q) {
					next unless keys %$q;
					$stuff = 1;
					for my $jobnum (reverse sort { $q->{$a}{priority} <=> $q->{$b}{priority} || $a <=> $b } keys %$q) {
						print STDERR "# looking to start $jobnum on $host\n" if $debug > 5;
						my $job = $q->{$jobnum};
						unless ($job->runnable) {
							print STDERR "# can't start $jobnum $job->{desc} on $host: not runnable\n" if $debug > 5;
							next;
						}
						delete $q->{$jobnum};
						$queue->startjob($host, $jobnum, $job);
						$queue->set_readiness($host);
						$redo = 1;
						next HOST;
					}
				}
				last;
			}
		}
		last unless $redo;
	}
	$queue->{host_is_over} = $new_host_is_over;
	return 0 if $stuff;
	return $queue->alldone();
}

sub suicide 
{
	print STDERR "DIE DIE DIE DIE DIE (DT2): $@";
	# exit 1; hangs!
	POSIX::_exit(1);
}

# a hook for EventQueue
sub unloop { }


sub startjob
{
	my ($queue, $host, $jobnum, $job) = @_;
	print STDERR "# starting $jobnum $job->{desc} on $host\n" if $debug > 1;
	my $hr = $queue->{status}{$host};
	$hr->{running}{$jobnum} = $job;
	$job->host($host);
	$job->start();
}


# This routine is re-enterant: it may be called from something it calls.
sub checkjobs
{
	my ($queue) = @_;
	my $found = 0;
	for my $host (keys %{$queue->{status}}) {
		print STDERR "# checking jobs on $host\n" if $debug > 7;
		my $hr = $queue->{status}{$host} || die;
		for my $jobnum (keys %{$hr->{running}}) {
			my $job = $hr->{running}{$jobnum};
			if ($job) {
				print STDERR "# checking $jobnum $job->{desc} on $host\n" if $debug > 8;
				$found++
					if defined $job->checkjob($queue);
			} else {
				print STDERR "# job $jobnum is undef!\n" if $debug;
				delete $hr->{running}{$jobnum};
				$found++;
			}

		}
		$queue->set_readiness($host);
	}
	return $found;
}

sub jobdone
{
	my ($job_queue, $job, $do_startmore, @exit_code) = @_;
	if ($job->{dependency_graph}) {
		if ($exit_code[0]) {
			print STDERR "Things dependent on $job->{desc} will never run: @exit_code\n";
			$job->{dependency_graph}->stuck_dependency($job, "exit @exit_code");
		} else {
			$job->{dependency_graph}->remove_dependency($job);
		}
		$job->{dependency_graph} = undef;
		# unlock_keys(%$job);
		# $job->{this_is_finished} = 1;
		# lock_keys(%$job);
	}
	$job_queue->job_part_finished($job, $do_startmore, @exit_code);
}

sub job_part_finished
{
	my ($job_queue, $job, $do_startmore, @exit_code) = @_;
	$do_startmore = 1 unless defined $do_startmore;

	my $host = $job->host;
	my $jobnum = $job->jobnum;

	print STDERR "# job $jobnum $job->{desc} on $host is done\n" if $debug > 5;

	my $hr = $job_queue->{status}{$host} or confess;
	delete $hr->{running}{$jobnum} or confess;

	$job_queue->set_readiness($host);

	$job_queue->startmore() if $do_startmore;
}

sub alldone
{
	my ($queue, $skip_status) = @_;
	$queue->status() if $debug && ! $skip_status;
	return 0 if keys %{$queue->{queue}};
	for my $host (keys %{$queue->{status}}) {
		my $hr = $queue->{status}{$host};
		return 0 unless $queue->{ready_hosts}{$host};
		return 0 if keys %{$hr->{queue}};
		return 0 if keys %{$hr->{running}};
		next unless $hr->{jobs_per_host} > 0;
	}
	return 1;
}

my $last_dump = time;

sub status
{
	my ($queue) = @_;
	return if time < $last_dump + $status_frequency;
	$last_dump = time;
	print STDERR "Queue Status\n";
	printf STDERR "\titems in main queue: %d, alldone=%d\n", scalar(keys %{$queue->{queue}}), $queue->alldone(1);
	print STDERR "\tHost overload condition is true\n" if $queue->{host_is_over};
	for my $host (sort keys %{$queue->{status}}) {
		my $hr = $queue->{status}{$host};
		printf STDERR "\titems in queue for %s: %d, items running: %s, host is %sready\n", 
			$host,
			scalar(keys(%{$hr->{queue}})),
			scalar(keys(%{$hr->{running}})),
			($queue->{ready_hosts}{$host} ? "" : "not ");
		for my $job (values %{$hr->{running}}) {
			print STDERR "\t\tRunning: $job->{jobnum} $job->{desc}\n";
		}
	}
	my $dg = $queue->{dependency_graph};
	printf "Dependency Graph items: %d independent (%d locked %d active), %d total, alldone=%s\n",
		scalar(keys(%{$dg->{independent}})),
		scalar(grep { $_->{dg_lock} } values %{$dg->{independent}}),
		scalar(grep { $_->{dg_active} } values %{$dg->{independent}}),
		scalar(keys(%{$dg->{addrmap}})),
		$dg->alldone
		if $dg;
}

my $canonicalizer;
sub get_canonicalizer
{
	return $canonicalizer if $canonicalizer;
	load($host_canonicalizer);
	$canonicalizer = $host_canonicalizer->new();
}

sub canonicalize
{
	my ($host) = @_;
	return get_canonicalizer()->canonicalize($host);
}

my $my_hostname;
sub my_hostname
{
	return $my_hostname if $my_hostname;
	$my_hostname = get_canonicalizer()->myname();
}

sub is_remote_host
{
	my ($host) = @_;
	return my_hostname() ne canonicalize($host);
}

sub graph
{
	my $queue = shift;
	if (@_) {
		die "a dependency graph was already set" if $queue->{dependency_graph};
		$queue->{dependency_graph} = shift;
	} elsif (! $queue->{dependency_graph}) {
		$queue->{dependency_graph} = Object::Dependency->new();
	}
	return $queue->{dependency_graph};
}


1;

__END__

=head1 NAME

 Proc::JobQueue - job queue with dependencies, base class

=head1 SYNOPSIS

 use Proc::JobQueue;

 $queue = Proc::JobQueue->new(%parameters);

 $queue->addhost($host, %parameters);

 $queue->add($job);
 $queue->add($job, $host);

 $queue->startmore();

 $queue->hold($new_value);

 $queue->checkjobs();

 $queue->jobdone($job, $do_startmore, @exit_code);

 $queue->alldone()

 $queue->status()

 $queue->startjob($host, $jobnum, $job);

=head1 DESCRIPTION

Generic queue of "jobs".   Most likely to be subclassed
for different situations.  Jobs are registered.  Hosts are
registered.  Jobs may or may not be tied to particular hosts.
Jobs are started on hosts.  Jobs may or may not have 
dependencies on each other.

Proc::JobQueue does not start jobs on its own: it needs something
to call C<startmore()> every now and then.   Two subsclasses
provide this complete Proc::JobQueue: 
L<Proc::JobQueue::EventQueue> which provides an event-based
framework using L<IO::Event> and L<Proc::JobQueue::BackgroundQueue>
which provides a simple loop-until-all-the-jobs-are-done construct.

From the jobs point of view, it will be started with:

  $job->jobnum($jobnum);
  $jobnum = $job->jobnum();
  $job->queue($queue);
  $job->host($host);
  $job->start();

When jobs complete, they must call:

  $queue->jobdone($job, $do_startmore, @exit_code);

Jobs are run on hosts which must be added with:

  $queue->addhost($hostname, jobs_per_host => $number_to_run_on_this_host_at_one_time)

Jobs can be 
shell commands (L<Proc::JobQueue::Command>), 
a sequence of other jobs (L<Proc::JobQueue::Sequence>),
some standard file operations (L<Proc::JobQueue::Move>, L<Proc::JobQueue::Sort>),
custom cubclasses of the base job class (L<Proc::JobQueue::Job>),
arbitrary perl code (L<Proc::JobQueue::DependencyJob>, L<Proc::JobQueue::Task>),
or arbitary perl code pushed to a remote system to run (L<Proc::JobQueue::RemoteDependencyJob>).

=head1 CONSTRUCTION

The parameters for C<new> are:

=over

=item jobs_per_host (default: 4)

Default number of jobs to run on each host simultaneously.  This can be overridden on a per-host basis.

=item host_overload (default: 120)

If any one host has more than this many jobs waiting for it, no can-run-on-any-host jobs will be started.
This is to prevent the queue for this one overloaded host from getting too large.

=item jobnum (default: 1000)

This is the starting job number.   Job numbers are sometimes displayed.  They increment for each new job. 

=item hold_all (default: 0)

If true, prevent any jobs from starting until C<$queue-E<gt>hold(0)> is called.

=item dependency_graph (default undef)

A dependency graph to track jobs and tasks that have dependencies and are not
yet ready to run because of their dependencies. 

=back

=head1 METHODS

=over

=item configure(%params)

Adjusts the same parameters that can be set with C<new>.

=item addhost($hostname, %params)

Register a new host.  Parameters are:

=over 

=item jobs_per_host

The number of jobs that can be run at once on this host.  This defaults
to the C<jobs_per_host> parameter of the C<$queue>.

=back

=item add($job, $host)

Add a job object to the runnable queue.   The job object must be 
a L<Proc::JobQueue::Job> or subclass of L<Proc::JobQueue::Job>.  
The C<$host> parameter is optional: if not set, the job can be run on any host.

The C<$job> object is started with:

  $job->jobnum($jobnum);
  $jobnum = $job->jobnum();
  $job->queue($queue);
  $job->host($host);
  $job->start();

When the job complets, it must call:

  $queue->jobdone($job, $do_startmore, @exit_code);

Jobs added this way must be ready to run with no dependencies on other jobs.
Jobs and tasks that have dependencies should be added with:

  $queue->graph->add($job);

=item graph([Object::Dependency->new()])

Get or set the dependency graph used to track jobs and tasks that have
dependencies.  The dependency graph is an L<Object::Dependency> object
(or at least something that implements the same API).  Items in the
dependency graph are not in the runnable queue.  They will be moved to
the runnable queue when they do not have any un-met dependencies.

=item jobdone($job, $do_startmore, @exit_code)

When jobs complete, they must call jobdone.  If C<$do_startmore> is true,
then C<startmore()> will be called.  A true exit code signals an
error and it is used by L<Proc::JobQueue::CommandQueue>.

=item job_part_finished($job)

This marks the C<$job> as complete and a new job can start in its place.
For L<Proc::JobQueue::DependencyJob> jobs, this leaves the dependency
in place.

=item alldone

This checks the job queue.  It returns true if all jobs have completed and
the queue is empty.

=item status

This prints a queue status to STDERR showing what's running on which hosts. 
Printing is supressed unless C<$Proc::JobQueue::status_frequency> seconds have
passed since the last call to C<status()>.

=item startmore

This will start more jobs if possible.  The return value is true if there are 
no more jobs to start.

=item hold($new_value)

Get (or set if $new_value is defined) the queue's hold-all-jobs parameter.
If hold-all-jobs is true, no jobs will be started or pulled out of the
dependency graph (if there is one).

=back

=head1 INTERNAL METHODS 

These methods may be needed by subclassers or anyone poking around the
internals:

=over

=item checkjobs

Check L<Proc::Background> style jobs to see if any have finished.

=item startjob($host, $jobnum, $job)

This starts a single job.  It is used by startmore() and probably should not be
used otherwise.

=item suicide

Called to shut down.  Used by L<Proc::JobQueue::EventQueue>.

=back

=head1 CANONICAL HOSTNAMES

Proc::JobQueue needs canonical hostnames.  It gets them by default
with L<Proc::JobQueue::CanonicalHostnames>.  You can override this 
default by overriding C<$Proc::JobQueue::host_canonicalizer> with
the name of a perl module to use instead of 
L<Proc::JobQueue::CanonicalHostnames>.  

Helper functions are provided by Proc::JobQueue and are available
via explicit import:

 use Proc::JobQueue qw(my_hostname canonicalize is_remote_host);

=head1 SEE ALSO

L<Proc::JobQueue::Job>
L<Proc::JobQueue::Command>
L<Proc::JobQueue::DependencyJob>
L<Proc::JobQueue::RemoteDependencyJob>
L<Proc::JobQueue::EventQueue>
L<Proc::JobQueue::BackgroundQueue>

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.   
Copyright (C) 2008-2010 David Sharnoff.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

