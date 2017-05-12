#!/usr/bin/perl

=head1 NAME

concurrent.pl - Start two tasks in parallel.

=head1 SYNOPSIS

perl concurrent.pl

=head1 DESCRIPTION

Shows how to start two tasks in parallel using Perl's syntaxic sugar.

=cut

use strict;
use warnings;

use Parallel::SubFork qw(sub_fork);

exit main();

sub main {
	
	my $task = sub_fork {
		foreach my $arg (1 .. 10) {
			print "PID: $$ > $arg\n";
			sleep 1;
		}
	};
	my $task2 = sub_fork { print "$$ > $_\n" and sleep 1 for @_ } 1 .. 10;

	$task->wait_for();
	$task2->wait_for();
	
	print "Tasks done\n";

	return 0;
}
