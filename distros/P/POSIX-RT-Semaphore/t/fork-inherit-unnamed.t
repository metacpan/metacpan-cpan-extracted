#! /usr/bin/perl
#
# fork-inherit-unnamed.t
#
# Can children manipulate our (anonymous) sems?
#

use Test::More tests => 6;
use strict;
use Fcntl qw(O_CREAT);
BEGIN { require 't/util.pl'; }
BEGIN { use_ok('POSIX::RT::Semaphore'); }

local (*R, *W);

SKIP: {
	my $sem;

	skip "sem_init: ENOSYS", 5
		unless is_implemented {
			$sem = POSIX::RT::Semaphore->init(1, 0);
		};

	ok($sem, "sem_init");
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
}

