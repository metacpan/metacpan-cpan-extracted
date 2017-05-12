#
# invalid.t
#
# invalid semaphores croak
#

use Test::More tests => 14;
use Fcntl qw(O_CREAT S_IRWXU);
BEGIN { require 't/util.pl'; }
use strict;

BEGIN { use_ok('POSIX::RT::Semaphore'); }

use constant SEMNAME => make_semname();

SKIP: {
	my $sem;

	skip "sem_open: ENOSYS", 7
		unless is_implemented {
			$sem = POSIX::RT::Semaphore->open(SEMNAME, O_CREAT, S_IRWXU, 1);
		};

	ok(zero_but_true($sem->close()), "close() -> zero_but_true");

	for my $method (qw|getvalue close post wait|) {
		eval { $sem->$method };
		ok($@ =~ /called on invalid psem/, "can't $method() closed psem");
	}
	eval{ $sem->timedwait(0) };
	ok($@ =~ /called on invalid psem/, "can't timedwait() closed psem");

	SKIP: {
		my $r;
		
		skip "sem_unlink: not implemented", 1
			unless is_implemented {
				$r = POSIX::RT::Semaphore->unlink(SEMNAME);
			};
		ok(zero_but_true($r), "unlink() -> zero_but_true");
	}

}

SKIP: {
	my $sem;

	skip "sem_init: ENOSYS", 6
		unless is_implemented {
			$sem = POSIX::RT::Semaphore->init(0, 1);
		};

	ok(zero_but_true($sem->destroy()), "destroy() -> zero_but_true");

	for my $method (qw|getvalue destroy post wait|) {
		eval { $sem->$method };
		ok($@ =~ /called on invalid psem/, "can't $method() destroyed psem");
	}
	eval{ $sem->timedwait(0) };
	ok($@ =~ /called on invalid psem/, "can't timedwait() destroyed psem");
}
