#
# ctors.t
#
# Test the constructors
#

use Test::More tests => 70;
use strict;
use Fcntl qw(O_CREAT S_IRWXU);
BEGIN { require 't/util.pl'; }
BEGIN { use_ok('POSIX::RT::Semaphore'); }

our $SEM = make_semname();

sub checkUnnamed($$) {
	my ($eval, $value) = @_;

	local $! = 0;
	my $sem = eval $eval;

	SKIP: {
		if (!$sem and $!{ENOSYS}) {
			skip "'$eval' unsupported", 4;
		}

		ok($sem, "$eval");
		isa_ok($sem, "POSIX::RT::Semaphore::Unnamed");
		ok_getvalue($sem, $value);
		ok($sem->destroy, "destroy()");
	}
}

sub checkNamed($$) {
	my ($eval, $value) = @_;
	local $! = 0;

	my $o_creat = ($eval =~ /\bO_CREAT\b/);
	my $sem = eval $eval;

	SKIP: {
		if (!$sem and $!{ENOSYS}) {
			skip "'$eval' unsupported", 4;
		}

		if (!$sem and !$o_creat and $^O eq 'cygwin') {
			# 2006-08-05 / mjp
			# cygwin sem_close()s destroy underlying semaphores?
			skip "Cygwin named psems not persistent", 4;
		}

		ok($sem, "$eval: $!");
		isa_ok($sem, "POSIX::RT::Semaphore::Named");
		ok_getvalue($sem, $value);
		ok($sem->close, "close()");
	}
}

checkUnnamed "POSIX::RT::Semaphore->init()", 1;
checkUnnamed "POSIX::RT::Semaphore->init(1)", 1;
checkUnnamed "POSIX::RT::Semaphore->init(0)", 1;
checkUnnamed "POSIX::RT::Semaphore->init(1, 7)", 7;
checkUnnamed "POSIX::RT::Semaphore->init(0, 7)", 7;
checkUnnamed "POSIX::RT::Semaphore::Unnamed->init(1)", 1;
checkUnnamed "POSIX::RT::Semaphore::Unnamed->init(0)", 1;
checkUnnamed "POSIX::RT::Semaphore::Unnamed->init(1, 7)", 7;
checkUnnamed "POSIX::RT::Semaphore::Unnamed->init(0, 7)", 7;

checkNamed "POSIX::RT::Semaphore->open('$SEM', O_CREAT, 0600, 1)", 1;
checkNamed "POSIX::RT::Semaphore->open('$SEM', O_CREAT, 0600)", 1;
checkNamed "POSIX::RT::Semaphore->open('$SEM', O_CREAT)", 1;
checkNamed "POSIX::RT::Semaphore->open('$SEM')", 1;
checkNamed "POSIX::RT::Semaphore::Named->open('$SEM', O_CREAT, 0600, 1)", 1;
checkNamed "POSIX::RT::Semaphore::Named->open('$SEM', O_CREAT, 0600)", 1;
checkNamed "POSIX::RT::Semaphore::Named->open('$SEM', O_CREAT)", 1;
checkNamed "POSIX::RT::Semaphore::Named->open('$SEM')", 1;

SKIP: {
	my $ok;
	skip "sem_unlink ENOSYS", 1
		unless is_implemented { $ok = POSIX::RT::Semaphore->unlink($SEM); };
	ok(zero_but_true($ok), "sem_unlink");
}
