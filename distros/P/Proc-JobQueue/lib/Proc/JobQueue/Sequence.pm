
package Proc::JobQueue::Sequence;

# $Id: Sequence.pm 13848 2009-07-23 21:34:00Z david $

use strict;
use warnings;
use Proc::JobQueue::Job;
use Hash::Util qw(lock_keys unlock_keys);
our @ISA = qw(Proc::JobQueue::Job);
use List::MoreUtils qw(all);
use Scalar::Util qw(weaken);
use Proc::JobQueue::DependencyTask;

sub new
{
	my ($pkg, $opts, $config, @jobs) = @_;

	my $job = $pkg->SUPER::new(
		opts		=> $opts,
		config		=> $config,
		jobs		=> \@jobs,
		priority	=> 20,
	);
	return $job;
}

sub startup
{
	my $job = shift;

	my $graph = $job->{queue}->graph();

	my @last = ();
	for my $subtask (@{$job->{jobs}}) {
		$graph->add($subtask, @last);
		@last = ( $subtask );
	}

	my $finish = Proc::JobQueue::DependencyTask->new(
		desc	=> 'mark Sequence as done',
		func	=> sub {
			$graph->remove_dependency($job)
				if $graph->is_dependency($job);
			return 'done';
		},
	);

	$graph->add($finish, @last);

	$job->{queue}->job_part_finished($job, 0);
}

__END__

=head1 NAME

 Proc::JobQueue::Sequence - do a sequence of background jobs

=head1 SYNOPSIS

 use Proc::JobQueue::BackgroundQueue;
 use aliased 'Proc::JobQueue::Sequence';
 use aliased 'Proc::JobQueue::Sort';
 use aliased 'Proc::JobQueue::Move';

 my $queue = new Proc::JobQueue::BackgroundQueue;

 my $job = Sequence->new($opts, $config,
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

