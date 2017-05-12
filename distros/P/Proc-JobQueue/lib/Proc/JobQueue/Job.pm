
package Proc::JobQueue::Job;

use strict;
use warnings;
use Hash::Util qw(lock_keys);
use Carp qw(confess);
use Tie::Function::Examples qw(%q_shell);
use Callback;
use Proc::Background;
use Proc::JobQueue qw(is_remote_host);
use Scalar::Util qw(weaken);

our $debug = $Proc::JobQueue::debug;

sub new 
{
	my ($pkg, %params) = @_;
	my $job = bless {
		desc			=> '',
		priority		=> 100,
		procbg			=> undef,
		run			=> undef,
		command			=> undef,
		queue			=> undef,
		jobnum			=> undef,
		postcb			=> undef,
		generate_command	=> undef,
		callback		=> undef,
		host			=> undef,
		jobnum			=> undef,
		on_failure		=> undef,
		errors			=> undef,
		status			=> 'queued',
		dependency_graph	=> undef,
		force_host		=> undef,
		%params
	}, $pkg;
	lock_keys(%$job);
	if ($job->{queue}) {
		$job->{queue}->add($job);
	}
	unless ($job->can_command || $job->can_callback) {
		confess "$pkg job needs a command or a callback";
	}
	unless ($job->{desc}) {
		if ($job->{command}) {
			$job->{desc} = $job->{command};
		} else {
			$job->{desc} = "$job"; # stringify
		}
	}
	return $job;
}

sub can_command
{
	my ($job) = @_;
	return 1 if $job->{command};
	return 1 if $job->{generate_command};
	return 1 if $job->can('command');
	return 0;
}

sub can_callback
{
	my ($job) = @_;
	return 1 if $job->{callback};
	return 1 if $job->can('startup');
	return 0;
}

sub start
{
	my ($job) = @_;

	my $host = $job->{host};
	my $queue = $job->{queue};
	my $jobnum = $job->{jobnum};

	$job->{status} = 'started';

	my $command = $job->{command} 
		|| ($job->{generate_command} && $job->{generate_command}->($job))
		|| ($job->can('command') && $job->command())
		;

	if ($command) {
		$job->{desc} = $command
			unless $job->{desc};
		if (is_remote_host($host)) {
			$command = "ssh $host -o BatchMode=yes -o StrictHostKeyChecking=no $q_shell{$command}";
		}
		$job->{run} = $command
			unless $job->{run};
		print "+ $command\n";
		$job->{procbg} = Proc::Background->new($command);
	} elsif ($job->{callback}) {
		if (ref($job->{callback}) eq 'Callback') {
			$job->{callback}->call($job);
		} else {
			$job->{callback}->($job, $host, $jobnum, $queue);
		}
	} elsif ($job->can('startup')) {
		$job->startup($job, $host, $jobnum, $queue);
	} else {
		die "don't know how to start $job";
	}
}

sub host
{
	my ($job, $host) = @_;
	$job->{host} = $host if defined $host;
	return $job->{host};
}

sub jobnum
{
	my ($job, $jobnum) = @_;
	$job->{jobnum} = $jobnum if defined $jobnum;
	return $job->{jobnum};
}

sub queue
{
	my ($job, $queue) = @_;
	if ($queue) {
		$job->{queue} = $queue;
		weaken $job->{queue};
	}
	return $job->{queue};
}

sub runnable
{
	return 1;
}

sub checkjob
{
	my ($job) = @_;
	print STDERR "# checking up on $job->{jobnum} $job->{desc} on $job->{host}\n" if $debug > 6;
	unless ($job->{procbg}) {
		print STDERR "# $job->{jobnum} is not a Proc::Background job\n" if $debug > 9;
		return undef;
	}
	if ($job->{procbg}->alive) {
		print STDERR "# $job->{jobnum} $job->{desc} is still alive\n" if $debug > 6;
		return undef;
	}
	my $queue = $job->{queue};
	my $e = $job->{procbg}->wait;
	$e >>= 8;
	print "# $job->{desc} on $job->{host} finished\n";
	$job->finished($e);
	return $e;
}

sub finished
{
	my ($job, @exit_code) = @_;
	return if $job->{status} eq 'finished';
	$job->{status} = 'finished';
	die "NO JOBNUM FOR $job" unless $job->{jobnum};
	print STDERR "# FINISHED $job->{jobnum} $job->{desc} on $job->{host}\n" if $debug > 7;
	if ($job->{postcb}) {
		$_->call($job, @exit_code)
			for @{$job->{postcb}};
		delete $job->{postcb};  # may clean circular references
	}
	my $queue = $job->{queue};
	undef $job->{queue};
	if ($queue) {
		if ($job->{jobnum}) {
			print STDERR "# calling JOBDONE for $job->{jobnum} $job->{desc} ($job->{status})\n" if $debug > 5;
			$queue->jobdone($job, 0, @exit_code);   # not re-entrant since startmore == 0
		} else {
			print STDERR "# NOT calling JOBDONE for $job->{jobnum} $job->{desc} ($job->{status})\n" if $debug;
		}
	}
	if ($exit_code[0]) {
		print STDERR "# calling failed(@exit_code) for $job->{jobnum} $job->{desc}\n" if $debug > 6;
		$job->failed(@exit_code);
	} else {
		print STDERR "# calling success() for $job->{jobnum} $job->{desc}\n" if $debug > 7;
		$job->success();
		print STDERR "# done calling success() for $job->{jobnum} $job->{desc}\n" if $debug > 9;
	}
	$queue->startmore if $queue;	# can be re-entrant
}


sub success
{
	my ($job) = @_;
	print STDERR "# Empty success on $job->{jobnum} $job->{desc}\n" if $debug > 8;
}

sub addpostcb
{
	my ($job, $cb1, @more) = @_;
	my $cb = new Callback($cb1, @more);
	$job->{postcb} = []
		unless $job->{postcb};
	push(@{$job->{postcb}}, $cb);
}

sub failed 
{
	my ($job, @exit_code) = @_;
	if ($job->{queue} && $job->{queue}{on_failure}) {
		$job->{queue}{on_failure}->($job, @exit_code);
	} else {
		die "job $job->{desc} failed with @exit_code";
	}
}

1;

__END__

=head1 NAME

Proc::JobQueue::Job - The $job objects for Proc::JobQueue

=head1 SYNOPSIS

 $job = Proc::JobQueue::Job->new(%params)

 $job->can_command()

 $job->can_callback()

 $job->start()

 $job->host($host)
 $job->host()

 $job->jobnum($jobnum)
 $job->jobnum()

 $job->queue($queue)
 $job->queue()

 $job->runnable()

 $job->finished()

 $job->success()

 $job->addpostcb()

=head1 DESCRIPTION

This is the base class for the C<$job> objects used by 
This class is designed to be overloaded.  For user APIs,
see the L</SEE ALSO> section.

=head1 CONSTRUCTION

The parameters for C<new()> are:

=over

=item desc

Sets a description for this job.

=item priority (default: 100)

Sets a priority for this job.  Higher number is higher priority.  Jobs with
higher priorities will be run first.

=item queue

A L<Proc::JobQueue> object, used for calling C<$queue-E<gt>jobdone()>.
Usually set by L<Proc::JobQueue::startjob()>.
This can also be set by calling C<queue($queue)>.

=item jobnum

A job number.
Usually set by L<Proc::JobQueue::startjob()>.
This can also be set by calling C<jobnum($jobnum)>.

=item host

The host this job will run on.  
Usually set by L<Proc::JobQueue::startjob()>.
This can also be set by calling C<jobnum($jobnum)>.

=item generate_command

A function callback to generate a unix command for this job. 

=item callback

A function callback that is this job.  The callback will be called when
the job should run.  The job will be passed as the argument to the callback.

 $job->callback($job).

=item on_failure

A function callback that will be invoked only if the job fails. 

 $on_failure->($job, @exit_code)

=back

=head1 METHODS 

=over

=item host, jobnum, queue

Get or set (if provided with a defined parameter) the
host, jobnum, or queue parameter for the job.

=item checkjob

Checks to see if the job is still running.  This only really works with
jobs which are unix commands.  If the job is done, C<checkjob()> will
invoke C<finished()>.  

=item finished(@exit_code)

Called to signal that the job has completed.  If C<$exit_code[0]> is true, 
then the job is considered to have failed and C<failed()> will be invoked.
Otherwise, C<sucess()> will be called.  In either case 
the post callback (if any),
C<$queue-E<gt>jobdone> and
C<$queue-E<gt>startmore> will be invoked.

=item addpostcb($callback, @args)

Add a callback to be called when the job completes.

The C<$job> object and the C<@exit_code> will be added to the callback's arguments.

=back

=head1 METHODS FOR SUBCLASSING

If you are subclassing Job then you may want to define these:

=over

=item startup

If defined, then a call to this method is what is used to start the job
running.  

=item sucess()

Called when the job succeeds.  Doesn't do anything -- it's a hook to override.

=item failed

Called when the job fails.   Invokes the on_failure action if there is one.

=item runnable

Returns true if the job is runnable at this time.

=item checkjob

A return value of undef indicates the job is still running.  A defined
value is the exit code for the job.

=item start

Starts this job.  This is usually called by 
C<Proc::JobQueue::startjob()>.

=back

=head1 SEE ALSO

L<Proc::JobQueue>
L<Proc::JobQueue::DependencyJob>
L<Proc::JobQueue::RemoteDependencyJob>
L<Proc::JobQueue::Command>
L<Proc::JobQueue::Sort>
L<Proc::JobQueue::Move>
L<Proc::JobQueue::Sequence>

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.
Copyright (C) 2008-2010 David Sharnoff.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

