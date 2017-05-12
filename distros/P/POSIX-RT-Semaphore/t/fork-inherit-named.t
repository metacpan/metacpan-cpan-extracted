#! /usr/bin/perl
#
# fork-inherit-named.t
#
# Can children manipulate our (named) sems?
#

use Test::More tests => 7;
use strict;
use Fcntl qw(O_CREAT);
BEGIN { require 't/util.pl'; }
BEGIN { use_ok('POSIX::RT::Semaphore'); }

use constant SEMNAME => make_semname();
local (*R, *W);

SKIP: {
	my $sem;

	skip "sem_open: ENOSYS", 6
		unless is_implemented {
			$sem = POSIX::RT::Semaphore->open(SEMNAME, O_CREAT, 0600, 0);
		};

	ok($sem, "sem_open");
	ok_getvalue($sem, 0, "getvalue == 0");

	die "pipe: $!\n" unless pipe(R, W);
	die "fork: $!\n" unless defined( my $pid = fork );

	if (!$pid) {
		Test::More->builder->no_ending(1);
		close(R);
		$sem->post;
		exit;
	}

	close(W);
	<R>;
	ok_getvalue($sem, 1);
	my $ok = $sem->trywait;
	if (!defined($ok) and $!{EAGAIN}) {
		skip "child couldn't manipulate sem", 2;
	}
	ok(1, "trywait");
	ok_getvalue($sem, 0);
	SKIP: {
		my $ok;
		skip "sem_unlink ENOSYS", 1
			unless is_implemented {$ok=POSIX::RT::Semaphore->unlink(SEMNAME);};
		ok(zero_but_true($ok), "sem_unlink");
	}
}
