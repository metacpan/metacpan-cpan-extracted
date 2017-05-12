#!/usr/bin/perl -w
# run a test of the SimpleCDB
# - kicks off a set of one writer and multiple readers, running
#   for around 2 minutes
#   - the example test script used does a full iteration over the DB to 
#     test that what goes in comes out
# - more of an example of locking/blocking than anything...
#
# - probably should use the more common Test::Harness setup

use strict;

my $program = 'examples/testsimplecdb.pl';

my $t;
my $n = 1_000;

$ENV{'PATH'} = '.';
$ENV{'PERL5LIB'} = '../';

print "\nstarting test\n", '-' x 80, "\n";

# see how long it takes to create a 1,000 record DB
$t = time();
system($program, $n, 0, 0);
$t = (time() - $t) || 1;

# run the SimpleCDB example test script with 10 readers
# - run for about 10 times as long as the 'base' time determined above, 
#   or a minimum of 2 minutes
# - if it was quick, do a few more records

$n *= 10 if $t <= 10;
$n *= 2  if $t <= 2;

$t *= 10;
$t = 120 if $t < 120;
$t = 300 if $t > 300;	# just in case of a *really* slow machine

printf "\nrunning test for %02d:%02d\n\n", int($t/60), $t % 60;

my $pid;
if ($pid = fork())
{
	eval
	{
		$SIG{CHLD} = sub { wait; die "SIGCHLD\n"; };
		# parent
		select(undef, undef, undef, $t);
		print "\nstopping test\n";
		kill INT => $pid;
		wait;
		die "non-zero exit code\n" if $?;
	};
	print "\n", '-' x 80, "\n";
	die "test FAILED [$@]\n" if $@;
	print "test PASSED\n";
}
else
{
	# child
	exec($program, $n, 5);
}
