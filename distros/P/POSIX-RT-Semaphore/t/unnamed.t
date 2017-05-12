# _unnamed_ semaphore tests

#########################

use Test::More tests => 17;
use Errno;
BEGIN { require 't/util.pl'; }
use strict;

BEGIN { use_ok('POSIX::RT::Semaphore'); }

SKIP: {
	my $sem;

	# -- sem_init ENOSYS?
	#
	skip "sem_init ENOSYS", 16
		unless is_implemented {
			$sem = POSIX::RT::Semaphore->init(0, 1);
		};
	ok($sem, "sem_init(sem_t *, 0, 1)");
	isa_ok($sem, "POSIX::RT::Semaphore::Unnamed");

	# -- ->name() extension (deprecated!)
	ok(! defined($sem->name), "name() (deprecated) undefined");

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

	# -- sem_destroy
	#
	ok(zero_but_true($sem->destroy), "destroy() -> zero_but_true");
}
