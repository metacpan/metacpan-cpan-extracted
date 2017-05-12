
package Proc::JobQueue::EventQueue;

use strict;
use warnings;
use Carp qw(confess);
require Proc::JobQueue;
use Time::HiRes qw(time);
use Object::Dependency;
require POSIX;

our @ISA = qw(Proc::JobQueue);

our $timer_interval = 6;
my $debug = 0;

sub new
{
	my ($pkg, %params) = @_;

	$params{dependency_graph} ||= Object::Dependency->new();

	my $queue = $pkg->SUPER::new(
		unloop			=> undef,
		startmore_in_progress	=> 0,
		on_failure		=> \&on_failure,
		%params
	);

	my $last_dump = time;

	my $timer = IO::Event->timer(
		interval	=> $params{timer_interval} || $timer_interval,
		cb		=> sub {
			print STDERR "beep!\n" if $debug;
			eval {
				$queue->startmore;
			};
			if ($@) {
				print STDERR "DIE DIE DIE DIE DIE (DT1): $@";
				# exit 1; hangs
				POSIX::_exit(1);
			};
			if ($debug && time > $last_dump + $timer_interval) {
				$params{dependency_graph}->dump_graph();
				$last_dump = time;
			}
			use POSIX ":sys_wait_h";
			my $k;
			do { $k = waitpid(-1, WNOHANG) } while $k > 0;
		},
	);

	$Event::DIED = sub {
		Event::verbose_exception_handler(@_);
		$queue->unloop();
		IO::Event::unloop_all();
	};

	return $queue;
}

sub unloop
{
	my ($queue) = @_;
	if ($queue->{unloop}) {
		$queue->unloop($queue->alldone);
	} else {
		IO::Event::unloop_all();
	}
}

sub on_failure
{
	my ($queue, $job, @exit_code) = @_; 
	if ($job->{on_failure}) {
		$job->{on_failure}->(@exit_code);
	} elsif ($job->{errors}) {
		$job->{errors}->("FAILED: $job->{desc}", @exit_code);
	} else {
		print STDERR "JOB $job->{desc} FAILED\nexit @exit_code\n";
	}
}


1;

__END__


There are two queues: the "jobs" that are ready to run, managed
by the superclass (Proc::JobQueue) and the tasks and jobs that 
have not had their prerequisites met that are in the 
Object::Dependency queue.

=head1 NAME

 Proc::JobQueue::EventQueue - JobQueue combined with IO::Event

=head1 SYNOPSIS

 use Proc::JobQueue::EventQueue;
 use Proc::JobQueue::DependencyTask;
 use Proc::JobQueue::DependencyJob;

 my $queue = Proc::JobQueue::EventQueue->new(
	hold_all => 1,
 );

 my $job = Proc::JobQueue::DependencyJob->new($queue, $callback_func);

 my $task => Proc::JobQueue::DependencyTask->new(desc => $desc, func => $callback_func);

 $dependency_graph->add($job);
 $dependency_graph->add($task);

 $job_queue->hold(0);

 $queue->startmore();

 IO::Event::loop();

 IO::Event::unloop_all() if $queue->alldone;

=head1 DESCRIPTION

This module is a sublcass of L<Proc::JobQueue>.  It combines the job
queue with L<IO::Event> for an asynchronous event loop.  L<IO::Event>
can use a select loop from L<Event>, L<AnyEvent> or its own.

The jobs that it runs are either full-fledged jobs, 
L<Proc::JobQueue::DependencyJob>, or 
simple synchronous one-shot perl callbacks that execute as soon as their
prerequisites are met: L<Proc::JobQueue::DependencyTask>.

Generally, the way to use this is to generate your dependency graph, then
create your job queue, then start some jobs.

=head1 API

In addition to the parameters supported by L<Proc::JobQueue>, the following
construction parameters are used:

=over

=item unloop

B<Code REF>.  If provided, invoke it to when the 
job queue is empty instead of calling C<IO::Event::unloop_all()>.

=item on_failure

B<Code REF>.  If provided, override the default behavior of how to
handle the failure of a job.  See the code for details.

=back

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.   
Copyright (C) 2008-2010 David Sharnoff.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

