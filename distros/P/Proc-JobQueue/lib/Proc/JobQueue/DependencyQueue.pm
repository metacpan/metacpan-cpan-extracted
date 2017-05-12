
package Proc::JobQueue::DependencyQueue;

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
		startmore_in_progress	=> 0,
		on_failure		=> \&on_failure,
		%params
	);

	if (defined(&IO::Event::unloop_all)) {
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
			IO::Event::unloop_all();
		};
	}

	return $queue;
}

sub unloop
{
	my ($queue) = @_;
	if (defined(&IO::Event::unloop_all)) {
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

 Proc::JobQueue::DependencyQueue - [DEPRECATED] JobQueue combined with a dependency graph

=head1 SYNOPSIS

 use Proc::JobQueue::DependencyQueue;
 use Object::Dependency;
 use Proc::JobQueue::DependencyTask;
 use Proc::JobQueue::DependencyJob;

 my $dependency_graph = Object::Dependency->new();

 my $job = Proc::JobQueue::DependencyJob->new($dependency_graph, $callback_func);

 my $task => Proc::JobQueue::DependencyTask->new(desc => $desc, func => $callback_func);

 $dependency_graph->add($job);
 $dependency_graph->add($task);

 my $queue = Proc::JobQueue::DependencyQueue->new(
	dependency_graph => $dependency_graph,
	hold_all => 1,
 );

 $job_queue->hold(0);

 $queue->startmore();

 IO::Event::loop();

 IO::Event::unloop_all() if $queue->alldone;

=head1 DESCRIPTION

This module is now deprecated in favor of L<Proc::JobQueue::EventQueue>.

This module is a sublcass of L<Proc::JobQueue>.  It combines a job
queue with a a dependency graph, L<Object::Dependency>.

The jobs that it runs are either full-fledged jobs, 
L<Proc::JobQueue::DependencyJob>, or 
simple synchronous one-shot perl callbacks that execute as soon as their
prerequisites are met: L<Proc::JobQueue::DependencyTask>.

Generally, the way to use this is to generate your dependency graph, then
create your job queue, then start some jobs.

It's expected that you'll use asynchronous I/O via L<IO::Event>, but that is not
required.   If you're using L<IO::Event>, it sets up a timer event to start more
jobs.  It also changes C<$Event::DIED> to unloop.

=head1 API

In addition to the parameters supported by L<Proc::JobQueue>, the following
construction parameters are used:

=over

=item dependency_graph

This should be a L<Object::Dependency> object.

=back

In addition to the methods inherited from L<Proc::JobQueue>, this module
adds:

=over

=item job_part_finished($job)

This marks the C<$job> as complete and a new job can start in its place.

=back

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.   
Copyright (C) 2008-2010 David Sharnoff.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

