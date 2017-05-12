#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# Make sure that the test don't get executed under Windows
BEGIN {

	if ($^O eq 'MSWin32') {
		plan skip_all => "Fork is broken under windows and IPC::SysV doesn't exit.";
	}
	else {
		plan tests => 29;
		use_ok('Parallel::SubFork::Task');
	}

}

# Load the custom utilities for semaphores
use FindBin;
use lib $FindBin::Bin;
use Tsemaphore;


exit main();


sub main {

	# Make sure that there's no hanging, it's better to fail the test due to a
	# timeout than to leave the test haging there forever.
	alarm(10);
	
	# Create a semaphore holding 2 values
	semaphore_init(28) or return 1;
	
	# Start a tastk through new(), execute()
	{
		semaphore_reset();
		my $task = Parallel::SubFork::Task->new(\&semaphore_task, 1 .. 10);
		$task->execute();
		test_semaphore_task_run($task, \&test_wait_for_timeout);
	}

	# Start a tastk through start()
	{
		semaphore_reset();
		my $task = Parallel::SubFork::Task->start(\&semaphore_task, 1 .. 10);
		test_semaphore_task_run($task, \&test_wait_for_timeout);
	}
	
	return 0;
}


sub test_wait_for_timeout {
	my ($task) = @_;
	
	# Check that we can wait with a timeout
	my $wait = $task->wait_for(1);
	ok($wait);
	$wait = $task->wait_for(1);
	ok($wait);
}
