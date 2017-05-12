#!/usr/bin/perl

=head1 NAME

progress.pl - Start a long task and give a periodic progress.

=head1 SYNOPSIS

perl progress.pl

=head1 DESCRIPTION

Shows how to start a task in parallel with a timeouts in order to provide a
feedback.

=cut

use strict;
use warnings;

use Time::HiRes qw(time);

use Parallel::SubFork::Task;

exit main();

sub main {
	
	# Start a long job
	my $start = time();
	my $task = Parallel::SubFork::Task->start(\&job, 10);
	
	# Wait for the results with a progress
	while ($task->wait_for(0.25)) {
		local $| = 1;
		printf "Process %d is running for %0.2f seconds\r", $task->pid, time() - $start;
	}

	# Access any of the properties
	printf "PID: $$ > PID of task was %s\n", $task->pid;
	printf "PID: $$ > Args of task where %s\n", join(", ", $task->args);
	printf "PID: $$ > Exit code: %d\n", $task->exit_code;
	
	return 0;
}


sub job {
	my ($time) = @_;
	sleep($time);
}
