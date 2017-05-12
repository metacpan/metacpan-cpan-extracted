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
		plan tests => 32;
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
	
	# Test the default values of a task after it's creation, the task is not
	# started.
	test_task_creation();	


	# Create a semaphore holding 2 values
	semaphore_init(24) or return 1;
	
	# Start a tastk through new(), execute()
	{
		semaphore_reset();
		my $task = Parallel::SubFork::Task->new(\&semaphore_task, 1 .. 10);
		$task->execute();
		test_semaphore_task_run($task);
	}

	# Start a tastk through start()
	{
		semaphore_reset();
		my $task = Parallel::SubFork::Task->start(\&semaphore_task, 1 .. 10);
		test_semaphore_task_run($task);
	}
	
	return 0;
}


#
# This test doesn't start a task, it simply creates one and checks for the
# default values.
#
sub test_task_creation {
	# Create a new task
	my $task = Parallel::SubFork::Task->new(\&semaphore_task, 1 .. 10);
	isa_ok($task, 'Parallel::SubFork::Task');
	
	# Assert that the task is constructed properly
	{
		my @args = $task->args();
		is_deeply(
			\@args, 
			[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 
			"Args are the same in list context"
		);
		
		my $args = $task->args();
		is($args, 10, "Args count is the same in scalar context");
		
	}
	is($task->code, \&semaphore_task, "Code is the same");
	
	is($task->pid, undef, "New task PID is undef");
	is($task->exit_code, undef, "New task exit_code is undef");
	is($task->status, undef, "New task status is undef");
}
