#!/usr/bin/perl

=head1 NAME

impatient.pl - Start a long task and kill it after a while.

=head1 SYNOPSIS

perl impatient.pl

=head1 DESCRIPTION

Shows how to start a task in parallel and how to kill it.

=cut

use strict;
use warnings;

use Parallel::SubFork::Task;

exit main();

sub main {
	
	# Start a long job
	print "Starting a long process...\n";
	my $task = Parallel::SubFork::Task->start(\&job, 10);
	
	# Wait for the results with a progress
	if ($task->wait_for(2)) {
		print "This takes too long!\n";
		$task->kill('KILL');
		$task->wait_for();
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
