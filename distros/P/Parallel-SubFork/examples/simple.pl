#!/usr/bin/perl

=head1 NAME

simple.pl - Start a long task in parallel.

=head1 SYNOPSIS

perl simple.pl

=head1 DESCRIPTION

Shows how to start a task in parallel.

=cut

use strict;
use warnings;

use Parallel::SubFork::Task;

exit main();

sub main {
	
	my $task = Parallel::SubFork::Task->start(\&job, 1 .. 10);
	$task->wait_for();

	# Access any of the properties
	printf "PID: $$ > PID of task was %s\n", $task->pid;
	printf "PID: $$ > Args of task where %s\n", join(", ", $task->args);
	printf "PID: $$ > Exit code: %d\n", $task->exit_code;
	
	return 0;
}


sub job {
	my (@args) = @_;
	foreach my $arg (@args) {
		print "PID: $$ > $arg\n";
	}
}
