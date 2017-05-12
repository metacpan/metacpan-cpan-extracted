#!/usr/bin/perl

use strict;
use warnings;

use POSIX qw(_exit);

use Test::More;

# Make sure that the test don't get executed under Windows
BEGIN {

	if ($^O eq 'MSWin32') {
		plan skip_all => "Fork is broken under windows.";
	}
	else {
		plan tests => 4;
		use_ok('Parallel::SubFork');
	}

}

my $PID = $$;

exit main();


sub main {
	
	alarm(10);
	
	# Create a new task
	my $manager = Parallel::SubFork->new();
	isa_ok($manager, 'Parallel::SubFork');
	
	my $task1 = $manager->start(\&task_exit);
	my $task2 = $manager->start(\&task_exec);
	
	$manager->wait_for_all();
	
	is($task1->exit_code, 42, "Exit worked properly");
	is($task2->exit_code, 52, "Exec worked properly");
	
	return 0;
}


sub task_exit {
	alarm(10);
	
	return 10 unless $$ != $PID;
	_exit(42);
	
	return 11;
}


sub task_exec {
	alarm(10);
	return 10 unless $$ != $PID;
	exec('perl', '-le', 'exit(52);') or _exit(11);
}
