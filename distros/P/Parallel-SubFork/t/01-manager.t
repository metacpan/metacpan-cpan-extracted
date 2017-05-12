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
		plan tests => 21;
		use_ok('Parallel::SubFork');
	}

}

# Load the custom utilities for semaphores
use FindBin;
use lib $FindBin::Bin;
use Tsemaphore;


my $PID = $$;


exit main();


sub main {
	
	# Create a semaphore holding 2 values
	semaphore_init(20) or return 1;
	
	
	# Create a new task
	my $manager = Parallel::SubFork->new();
	isa_ok($manager, 'Parallel::SubFork');
	
	# Make sure that we are the main dispatcher
	$manager->_assert_is_dispatcher();
	pass("Parent is the dispatcher");
	
	# Assert that there are no tasks
	{
		my @tasks = $manager->tasks();
		is_deeply(\@tasks, [], "No tasks in list context");
	
		my $tasks = $manager->tasks();
		is($tasks, 0, "No tasks in scalar context");
		
		foreach my $task ($manager->tasks()) {
			fail("Expected no task but got $task");
		}
	}
	
	
	# Start a sub task
	my $task = $manager->start(\&semaphore_task, 1 .. 10);
	isa_ok($task, 'Parallel::SubFork::Task');
	
	# Make sure that there's no hanging, it's better to fail the test due to a
	# timeout than to leave the test haging there forever.
	alarm(10);
	
	
	# Assert that there's a task
	{
		my @tasks = $manager->tasks();
		is_deeply(\@tasks, [$task], "One task in list context");
	
		my $tasks = $manager->tasks();
		is($tasks, 1, "One task in scalar context");
		
		foreach my $tmp ($manager->tasks()) {
			is($tmp, $task, "Looping through tasks")
		}
	}

	test_semaphore_task_run($task);
	
	return 0;
}
