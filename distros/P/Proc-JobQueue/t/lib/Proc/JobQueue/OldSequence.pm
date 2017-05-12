
package Proc::JobQueue::OldSequence;

# $Id: Sequence.pm 13848 2009-07-23 21:34:00Z david $

use strict;
use warnings;
use Proc::JobQueue::Job;
use Hash::Util qw(lock_keys unlock_keys);
our @ISA = qw(Proc::JobQueue::Job);
use List::MoreUtils qw(all);
use Scalar::Util qw(weaken);

use overload
	'""' => \&describe;

my $debug = $Proc::JobQueue::debug;

my $ijobid = "A100";

sub new
{
	my ($pkg, $opts, $config, @jobs) = @_;

	my $job = $pkg->SUPER::new(
		opts		=> $opts,
		config		=> $config,
		jobs		=> \@jobs,
		fubar		=> 0,
		priority	=> 20,
		completed	=> 0,
		state		=> 'waiting',
		runnable	=> '?',
		check		=> '?',
		ijobid		=> $ijobid++,
		queue_copy	=> undef,
	);
	return $job;
}

sub describe
{
	my ($job) = @_;
	my $jobs = $job->{jobs};
	my $num = $job->jobnum || '';
	if (@$jobs) {
		my $outof = @$jobs;
		return "OldSequence $num/$job->{ijobid}, $job->{completed}/$outof completed, top of queue $job->{state}/$job->{status} {$job->{runnable}/$job->{check}}: $jobs->[0]{desc}";
	} else {
		return "OldSequence $num/$job->{ijobid}, $job->{completed} completed, no more";
	}
}

sub can_callback
{
	my ($job) = @_;
	return all { $_->can_callback } @{$job->{jobs}};
}

sub can_command
{
	my ($job) = @_;
	return all { $_->can_command } @{$job->{jobs}};
}

sub runnable
{
	my $job = shift;
	$job->{runnable} = $job->{jobs}[0]->runnable(@_);
	$job->{desc} = $job->describe;
	return $job->{runnable};
}

#
# SUPER::start will call startup()
#
sub start
{	
	my $job = shift;
	print "START $job\n" if $debug > 8;
	$job->{state} = 'running';
	$job->{desc} = $job->describe;
	$job->SUPER::start(@_);
}

sub startup
{
	my $job = shift;
	print "STARTUP $job\n" if $debug > 1;
	$job->{jobs}[0]->start(@_);
}

sub checkjob
{
	my $job = shift;
	print "CHECKJOB $job\n" if $debug > 8;
	if ($job->{fubar}) {
		print "CHECKJOB: fubar->1\n" if $debug > 8;
		return 1;
	}
	unless (@{$job->{jobs}}) {
		print "CHECKJOB: no more jobs -> 0\n" if $debug > 8;
		return 0;
	}
	my $e = $job->{jobs}[0]->checkjob(@_);
	if (defined($e)) {
		print "CHECKJOB CALLING FINISHED ($e)\n" if $debug > 8;
		$job->finished($e);
	} else {
		print "CHECKJOB: not done\n" if $debug > 3;
	}
	return $e;
}

sub jobnum
{
	my ($job, $jobnum) = @_;
	$job->{jobs}[0]->jobnum($jobnum . ":" . scalar(@{$job->{jobs}}))
		if $jobnum;
	$job->SUPER::jobnum($jobnum);
}

sub host
{
	my $job = shift;
	$job->{jobs}[0]->host(@_);
	$job->SUPER::host(@_);
}

sub finished
{
	my $job = shift;
	print "FINISHED $job\n" if $debug > 8;
	$job->{completed}++;
	$job->SUPER::finished(@_);	# should call success()
}

sub success 
{
	#
	# By this point, the JobQueue is done with this job so it needs
	# to be re-submitted if it's to run again.
	#
	my ($job) = @_;
	print "# SEQUENCE success on $job->{jobnum}\n" if $debug > 8;
	my $queue = $job->{queue} || $job->{queue_copy};
	my $host = $job->{host};
	my $first = $job->{jobs}[0];
	shift(@{$job->{jobs}});
	my $next = $job->{jobs}[0];
	if ($next) {
		$job->{state} = 'waiting again';
		$job->{desc} = $job->describe;
		$job->{status} = 'queued';    # reaching into ::Job's data
		$job->jobnum($job->{jobnum}); # side effect: set jobnum of child job
		$next->host($job->host);      # keep on the same host for better caching
		$queue->add($job);
	} else {
		print STDERR "no more jobs in sequence\n" if $debug > 1;
	}
	$first->finished(0);
}

sub failed 
{
	my ($job, @e) = @_;
	$job->SUPER::failed(@e);
	$job->{state} = "failed (@e)";
	my $first = $job->{jobs}[0];
	$first->finished(@e);
	$job->{fubar} = 1;
}

sub queue
{
	my ($job, $queue) = @_;
	if ($queue) {
		$job->{queue_copy} = $queue;
		weaken $job->{queue_copy};
	}
	$job->SUPER::queue($queue);
}

1;

__END__

=head1 NAME

 Proc::JobQueue::OldSequence - do a sequence of background jobs

=head1 SYNOPSIS

 use Proc::JobQueue::BackgroundQueue;
 use aliased 'Proc::JobQueue::OldSequence';
 use aliased 'Proc::JobQueue::Sort';
 use aliased 'Proc::JobQueue::Move';

 my $queue = new Proc::JobQueue::BackgroundQueue;

 my $job = OldSequence->new($opts, $config,
	Sort->new($opts, $config, $sorted_output, @unsorted_files),
	Move->new($opts, $config, $sorted_output, $final_name, $final_host),
 );

 $queue->add($job);

 $queue->finish;

=head1 DESCRIPTION

This is a subclass of L<Proc::JobQueue::Job>.
In the background, do a sequence of jobs.  If a job fails,
the jobs later in the sequence are cancelled.

=head1 SEE ALSO

L<Proc::JobQueue>
L<Proc::JobQueue::Job>
L<Proc::JobQueue::BackgroundQueue>
L<Proc::JobQueue::Command>
L<Proc::JobQueue::Move>
L<Proc::JobQueue::Sort>

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.
Copyright (C) 2008-2010 David Sharnoff.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 licenses.

