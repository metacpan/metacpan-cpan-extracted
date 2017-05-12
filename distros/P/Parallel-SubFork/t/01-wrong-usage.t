#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


# Make sure that the test don't get executed under Windows
BEGIN {

	if ($^O eq 'MSWin32') {
		plan skip_all => "Fork is broken under windows.";
	}
	else {
		plan tests => 83;
		use_ok('Parallel::SubFork');
		use_ok('Parallel::SubFork::Task');
		use Parallel::SubFork qw(sub_fork);
	}

}


my $PID = $$;
my $MANAGER;
my $TASK;

exit main();


sub main {
	
	alarm(10);
	
	# Create a new task
	$MANAGER = Parallel::SubFork->new();
	isa_ok($MANAGER, 'Parallel::SubFork');
	
	# Start a sub task and try to execute forbiden code from there
	my $task_wait_for_all = $MANAGER->start(\&task_wait_for_all);
	my $task_start = $MANAGER->start(\&task_start);
	$TASK = $MANAGER->start(sub {return 42;});
	my $task_wait_for = $MANAGER->start(\&task_wait_for);
	my $task_sub_fork = sub_fork(\&task_wait_for);

	# Wait for the tasks to resume
	$MANAGER->wait_for_all();
	$task_sub_fork->wait_for();
	
	is($task_wait_for_all->exit_code, 75, "Child process can't call wait_for_all()");
	is($task_start->exit_code, 61, "Child process can't call start()");
	is($TASK->exit_code, 42, "Generic task");
	is($task_wait_for->exit_code, 23, "Child process can't call start()");
	is($task_sub_fork->exit_code, 23, "2Child process can't call start()");
	
	
	# Check that we can't reexecute the tasks
	foreach my $task ($task_wait_for_all, $task_start, $TASK, $task_wait_for, $task_sub_fork) {
		assert_exception(
			qr/^Task already exectuted/,
			sub { $task->execute(); }
		);
	}
	
	
	
	##
	# Check the methods expecting a mandatory code ref enforce it
	my $regexp_param_code_ref = qr/^First parameter must be a code reference/;
	
	my @all_args = (
		[],
		['text'],
		[1],
		[ ['array'] ],
		[ { an => 'hash' } ],
	);
	foreach my $args (@all_args) {
		my @args = @{ $args };

		assert_exception(
			$regexp_param_code_ref,
			sub { $MANAGER->start(@args); }
		);

		assert_exception(
			$regexp_param_code_ref,
			sub { Parallel::SubFork::Task->new(@args); }
		);

		assert_exception(
			$regexp_param_code_ref,
			sub { Parallel::SubFork::Task->start(@args); }
		);

		# Start a task that has no code reference
		my $task_bad_code = Parallel::SubFork::Task->new(sub {});
		$task_bad_code->code(undef);
		assert_exception(
			qr/^\QTask requires a valid code reference (function)\E/,
			sub { $task_bad_code->execute(); }
		);
	}

	return 0;
}


sub assert_exception {
	my ($regexp, $code) = @_;
	is(ref $regexp, 'Regexp', "Expecting a regexp as assert_exception 1st argument");
	is(ref $code, 'CODE', "Expecting a code ref as assert_exception 2nd argument");

	eval {
		$code->();
	};
	if (my $error = $@) {
		ok($error =~ /$regexp/, "Code raised an exception");
		return;
	}
	
	fail("Expected to raise an exception");
}


#
# Test that a task can't call $manager->wait_for_all()
#
sub task_wait_for_all {
	my (@args) = @_;

	alarm(10);

	return 10 unless $$ != $PID;

	my $fail;
	eval {
		$MANAGER->wait_for_all();
		$fail = 1;
	};
	if (my $error = $@) {
		my $match = "Process $$ is not the main dispatcher";
		return 11 unless $error =~ /^\Q$match\E/;
	}
	return 12 if $fail;

	return 75;
}


#
# Test that a task can't call $manager->start()
#
sub task_start {
	my (@args) = @_;

	alarm(10);

	return 10 unless $$ != $PID;

	my $fail;
	eval {
		$MANAGER->start(
			sub {
				die "***** TEST FAILED ($$ <-> $PID) *****";
			}
		);
		$fail = 1;
	};
	if (my $error = $@) {
		my $match = "Process $$ is not the main dispatcher";
		return 11 unless $error =~ /^\Q$match\E/;
	}
	return 12 if $fail;

	return 61;
}


#
# Test that a task can't call $task->wait_for()
#
sub task_wait_for {
	my (@args) = @_;

	alarm(10);

	my $return = 23;

	return 10 unless $$ != $PID;

	my $fail;
	eval {
		$TASK->wait_for();
		$fail = 1;
	};
	if (my $error = $@) {
		my $match = "Only the parent process can wait for the task";
		return 11 unless $error =~ /^\Q$match\E/;
	}
	return 12 if $fail;

	return 23;
}
