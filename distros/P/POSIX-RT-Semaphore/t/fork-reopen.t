#! /usr/bin/perl
#
# fork-reopen.t
#
# Can children manipulate sems by name?
#

use Test::More tests => 7;
use strict;
use Fcntl qw(O_CREAT);
BEGIN { require 't/util.pl'; }
BEGIN { use_ok('POSIX::RT::Semaphore'); }

use constant SEMNAME => make_semname();

sub child_sem($) {
	my $method = shift;
	my $pid;
	die "fork: $!\n" unless defined($pid = fork);

	if (!$pid) {
		Test::More->builder->no_ending(1);
		my $sem = POSIX::RT::Semaphore->open(SEMNAME, O_CREAT, 0600, 0);
		$sem->$method;
		exit;
	}
	waitpid($pid, 0);
}

SKIP: {
	my $sem;

	skip "sem_open: ENOSYS", 6
		unless is_implemented {
			$sem = POSIX::RT::Semaphore->open(SEMNAME, O_CREAT, 0600, 0);
		};

	ok($sem, "sem_open");
	ok_getvalue($sem, 0, "getvalue == 0");
	$sem->post;
	ok_getvalue($sem, 1, "getvalue == 1");

	child_sem("post");
	child_sem("post");

	ok_getvalue($sem, 3, "getvalue == 3");
	child_sem("wait");
	ok_getvalue($sem, 2, "getvalue == 2");
	SKIP: {
		my $ok;
		skip "sem_unlink ENOSYS", 1
			unless is_implemented {$ok=POSIX::RT::Semaphore->unlink(SEMNAME);};
		ok(zero_but_true($ok), "sem_unlink");
	}
}
