
package Proc::JobQueue::DependencyJob;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Callback;
require Proc::JobQueue::Job;
use Carp qw(confess);

our @ISA = qw(Proc::JobQueue::Job);

sub new
{
	my ($pkg, $dependency_graph, $func, %params) = @_;
	$params{args} ||= [];

	my $cb = (blessed($func) && $func->isa('Callback')) 
		? $func
		: Callback->new($func, @{$params{args}});

	delete $params{args};

	my $job = $pkg->SUPER::new(
		dependency_graph	=> $dependency_graph,
		dep_cb			=> $cb,
		started			=> 0,
		runnable		=> 0,
		%params,
	);
	$dependency_graph->add($job);
	return $job;
}

sub startup
{
	my ($job) = @_;

	my $host = $job->{host};
	my $jobnum = $job->{jobnum};
	my $job_queue = $job->{queue};

	my $cb = $job->{dep_cb};
	$job->{dep_cb} = undef;
	my ($code, $f, @a) = $cb->call($job);
	if ($code eq 'job-done,dep-keep') {
		$job->{dep_cb} = new Callback ($f, @a);
		$job_queue->jobdone($job);
	} elsif ($code eq 'all-done') {
		$job->finished(0);
	} elsif ($code eq 'job-keep,dep-done') {
		$job->{dependency_graph}->remove_dependency($job);
		undef $job->{dependency_graph};
	} elsif ($code eq 'all-keep') {
		# okay
	} else {
		die "unknown code '$code' from $job->{desc}";
	}
}

sub job_part_finished
{
	my ($job, $do_startmore) = @_;
	my $queue = $job->{queue};
	return unless $queue;
	$job->{queue} = undef;
	$queue->job_part_finished($job, $do_startmore);
}

sub success
{
	my ($job) = @_;
	if ($job->{dependency_graph}) {
		$job->{dependency_graph}->remove_dependency($job);
		undef $job->{dependency_graph};
	}
	$job->SUPER::success();
}

sub failed
{
	my ($job, @exit_code) = @_;
	if ($job->{dependency_graph}) {
		$job->{dependency_graph}->stuck_dependency($job);
		undef $job->{dependency_graph};
	}
	print STDERR "Job $job->{desc} failed, all dependent tasks cancelled\n";
}

sub failure
{
	my ($job, @exit_code) = @_;
	if ($exit_code[0]) {
		$job->finished(@exit_code);
	} else {
		$job->finished('FAILED', @exit_code);
	}
}

1;

__END__

=head1 NAME

 Proc::JobQueue::DependencyJob - dependency-aware job object for Proc::JobQueue

=head1 SYNOPSIS

 use Proc::JobQueue::DependencyJob;
 use Object::Dependency;

 $graph = Object::Dependency->new()

 $job = Proc::JobQueue::DependencyJob->new($graph, $callback_func, %params);

 $job->startup()

 $job->job_part_finished()

 $job->jobdone();

 $job->failure(@exit_code)

=head1 DESCRIPTION

Proc::JobQueue::DependencyJob is a subclass of 
L<Proc::JobQueue::Job> used to define jobs to run from a 
L<Proc::JobQueue>.

DependencyJob jobs are perl objects with a callback API.  C<$job-E<gt>startup()> is
called to start the job.  That in turn calls, the callback provided in construction.  The
C<$job> object is added to the argument list for the callback.

The return value from the callback lets C<startup()> know what to do
next: the job is finished; the job finished but it remains a 
dependency in the dependency graph; the job is not done but it should
be removed from the dependency graph; or the job is not done and 
should remain in the dependency graph.

If the job is not done, then it needs to signal it's completion later
by calling C<$job-E<gt>finished(0)> or C<$job-E<gt>failure($reason)>.

=head1 CONSTRUCTION

These jobs require a dependency graph for construction.  The C<%params> 
parameter represents additional parameters passed to L<Proc::JobQueue::Job>.

=head1 METHODS

In addition to the methods in L<Proc::JobQueue::Job>, DependencyJob provides:

=over

=item startup()

This is called by C<Proc::JobQueue::Job::start()>.  It calls the 
callback.  The callback must return.  A reference to self (C<$job>)
is provided as an argument to the callback.
The return value from the callback must be a string from the following set:

=over

=item C<all-done>

The job has completed and the dependency in the dependency graph should
be removed.

=item C<all-keep>

The job has not completed and the dependency in the dependency graph should
be kept.

The job can be marked as done with:

 $job->job_part_finished($do_startmore)

The dependency can be marked as completed with:

 $job->{dependency_graph}->remove_dependency($job);

Or both the job and the dependency can be marked as done/completed with
one call:

 $job->finished(0);

=item C<job-done,dep-keep>

The job has completed, but it should not be removed from the dependency
graph.  Somehow the callback must arrange that the dependency graph
dependency gets removed later:

 $job->{dependency_graph}->remove_dependency($job);

=item C<job-keep,dep-done>

The job is not done, but the dependency has been been fullfilled.
The job can be marked done with:

 $job->finished(0);

Or 

 $job->job_part_finished($do_startmore)

Things which depend on this job are eligible to be started.

=back

=item failed()

This overrides L<JobQueue::Job>'s failure() method to mark the dependency as
stuck.

=item failure(@reason)

This marks this job as failed.

=back

=head1 SEE ALSO

L<Proc::JobQueue::EventQueue>
L<Proc::JobQueue::Job>
L<Proc::JobQueue::DependencyTask>
L<Proc::JobQueue>

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.   
Copyright (C) 2008-2010 David Sharnoff.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

