#!/usr/bin/perl
package Tsemaphore;


use strict;
use warnings;

use IPC::SysV qw(IPC_PRIVATE S_IRWXU IPC_CREAT);
use IPC::Semaphore;
use POSIX qw(WNOHANG);

use Test::More;

# This is a testing framework so we can do ugly things like exporting symbols by
# default into the caller's context
use base 'Exporter';
our @EXPORT = qw(
	semaphore_init
	semaphore_reset
	semaphore_task
	test_semaphore_task_run
);

#	semaphore_let_go
#	semaphore_wait_for
#	$SEMAPHORE_POINT_A
#	$SEMAPHORE_POINT_B

# Semaphores are used for synchronizing the parent (main code) and the child
# (task). The idea is that the parent will check that the child is actually
# running. In order for this test to be successful the child has to be running!
# To ensure that the child is running semaphores are used. The child will not be
# allowed to finish until the parent has approved it. On the other hand the 
# parent will not be allowed to check for child's process until the child is
# alive and notifies the parent of his existence.
#
# Parent                 |  Child
# -----------------------|-----------
#                        |
# Init                   |
# Create semaphores      |
#                        |
# Fork task              | Task start
#                        |
# Wait for A             | Join A
#                        |
# Check child is running |
#                        |
# Join B                 | Wait for B
#                        |
# Continue tests         | Finish
#                        |
# Finish                 |
#
my $SEMAPHORE;
my $SEMAPHORE_POINT_A = 0;
my $SEMAPHORE_POINT_B = 1;

my $PID = $$;

END {
	$SEMAPHORE->remove if defined $SEMAPHORE;
}

#
# Creates a new set of semaphores. If the semaphores can't be created it returns
# false.
#
sub semaphore_init {
	my ($skip_count) = @_;
	die "Usage: semaphore_init(skip_count)" unless @_;
	
	# Remove the previous semaphore
	$SEMAPHORE->remove if defined $SEMAPHORE;
	
	# Create a semaphore holding 2 values
	$SEMAPHORE = IPC::Semaphore->new(IPC_PRIVATE, 2, S_IRWXU | IPC_CREAT);
	if (! defined $SEMAPHORE) {
		# Bad implementation of IPC::Semaphore
		SKIP: {
			skip "Can't create a semaphore", $skip_count;
		}
		return 0;
	}
	isa_ok($SEMAPHORE, 'IPC::Semaphore');
	
	semaphore_reset();
	return 1;
}


#
# Resets the semaphores to 0
#
sub semaphore_reset {
	# Clear the semaphores
	my $return = $SEMAPHORE->setall(0, 0);
	ok(defined($return), "Semaphore cleared");
}


#
# Tell the other process that he can go futher since we have reached the rally
# point. We give the other process one more resource in order to go on.
#
sub semaphore_let_go {
	my ($who) = @_;
	$SEMAPHORE->op($who, 1, 0);
}


#
# Wait for the other process to reach his rally point and to let us go further.
# We remove a resource from this process, this will make us wait until the other
# process reaches the rally point.
#
sub semaphore_wait_for {
	my ($who) = @_;
	$SEMAPHORE->op($who, -1, 0);
}


#
# Special task that's meant to be run in a separate process. The return value is
# used to tell if the task run successfully. If this task returns 57 then it has
# succeed any other value must be regarded as a failure.
#
sub semaphore_task {
	my (@args) = @_;
	
	# Make sure that there's no hanging
	alarm(10);
	

	# Tell the parent that we are ready
	semaphore_let_go($SEMAPHORE_POINT_A) or return 10;

	
	# Wait for the parent to let us go further
	semaphore_wait_for($SEMAPHORE_POINT_B) or return 11;

	return 12 unless $$ != $PID;
	
	my @wanted = qw(1 2 3 4 5 6 7 8 9 10);
	return 13 unless eq_array(\@args, \@wanted);
	
	return 57;
}


#
# Execute a task and test that it's running properly. If a callback is passed
# then it will be invoked while the task is running.
#
sub test_semaphore_task_run {
	my ($task, $callback) = @_;

	# Make sure that there's no hanging, it's better to fail the test due to a
	# timeout than to leave the test haging there forever.
	alarm(10);
	

	isa_ok($task, 'Parallel::SubFork::Task');
	
	# Wait for the kid to be ready
	my $return = semaphore_wait_for($SEMAPHORE_POINT_A);


	# Make sure that the task is in a different process
	ok($$ != $task->pid, "Taks has a different PID");
	{
		my $kid = waitpid($task->pid, WNOHANG);
		is($kid, 0, "Child process still running");
	}
	
	
	# If the user provided a callback invoke it.
	if (ref $callback eq 'CODE') {
		$callback->($task);
	}
	

	# Tell the kid that we finish checking it, it can now resume
	$return = semaphore_let_go($SEMAPHORE_POINT_B);
	ok($return, "Removed resource to semaphore B");
	
	
	
	# Wait for the task to resume
	$task->wait_for();
	is($task->exit_code, 57, "Task exit code is fine");
	is($task->status, 57 << 8, "Task status is fine");

	is_deeply(
		[ $task->args ], 
		[ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], 
		"Task args are intact"
	);

	# Wait some more, is useless but it should work
	$task->wait_for();
	is($task->exit_code, 57, "Second wait on the same task, exit code fine");
	is($task->status, 57 << 8, "Second wait on the same task, status fine");
	

	# Make sure that there are no other tasks
	{
		my $kid = waitpid(-1, WNOHANG);
		is($kid, -1, "No more processes");
	}
}


# Return a true value
1;

