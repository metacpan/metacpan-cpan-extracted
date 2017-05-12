# _named_ semaphore tests

#########################

use Test::More tests => 17;
use Errno;
use Fcntl qw(O_CREAT S_IRWXU);
BEGIN { require 't/util.pl'; }
use strict;

BEGIN { use_ok('POSIX::RT::Semaphore'); }

use constant SEMNAME => make_semname();

SKIP: {
	my $sem;

	# -- sem_open ENOSYS?
	#
	skip "sem_open: not implemented", 16
		unless is_implemented {
			$sem = POSIX::RT::Semaphore->open(SEMNAME, O_CREAT, S_IRWXU, 1);
		};

	ok($sem, "sem_open");
	isa_ok($sem, "POSIX::RT::Semaphore::Named");

	# -- ->name() method
	#
	ok($sem->name eq SEMNAME, "name() (" .$sem->name .") eq " . SEMNAME);

	# -- Basic methods: wait, post, getvalue, trywait
	#
	ok_getvalue($sem, 1, "getvalue() -> 1");
	ok(zero_but_true($sem->wait), "wait() -> zero-but-true");
	ok_getvalue($sem, 0, "getvalue() -> 0");
	$! = 0;
	ok((!defined($sem->trywait) and $!{EAGAIN}), "trywait EAGAIN");
	ok(zero_but_true($sem->post), "post() -> zero-but-true");
	ok(zero_but_true($sem->post), "post() -> zero-but-true");
	ok_getvalue($sem, 2, "getvalue() -> 2");
  	ok(zero_but_true($sem->trywait), "trywait() -> zero-but-true");
	ok_getvalue($sem, 1, "getvalue() == 1");

	# -- Maybe supported: sem_timedwait
	#
	SKIP: {
		my $r;
		skip "sem_timedwait ENOSYS", 3
			unless is_implemented { $r = $sem->timedwait(time() + 2); };
		ok(zero_but_true($r), "timedwait() -> zero-but-true");
		ok_getvalue($sem, 0, "getvalue() == 0");

		$! = 0;
		$r = $sem->timedwait(time()  + 2);
		ok(!defined($r) && $!{ETIMEDOUT}, "timedwait ETIMEDOUT");
	}

	# -- Maybe unimplemented:  sem_unlink (Cygwin?!)
	#
	SKIP: {
		my $r;
		
		skip "sem_unlink: not implemented", 1
			unless is_implemented {
				$r = POSIX::RT::Semaphore->unlink(SEMNAME);
			};
		ok(zero_but_true($r), "unlink() -> zero_but_true");
	}

}
