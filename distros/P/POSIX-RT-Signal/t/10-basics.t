#!perl

use strict;
use warnings;
use Errno;
use Test::More 0.88;
use Test::Exception;
use POSIX::RT::Signal ':all';
use POSIX qw/sigprocmask SIG_BLOCK SIG_UNBLOCK SIGUSR1 SIGALRM setlocale LC_ALL EINVAL/;

use Time::HiRes qw/alarm/;

setlocale(LC_ALL, 'C');

{
	my $status = 1;
	my $should_match = 1;
	local $SIG{USR1} = sub { is($status++, $should_match, "status is $should_match") };
	kill SIGUSR1, $$;
	is($status, 2, 'Status is 2');
	$should_match = $status;
	sigqueue($$, 'USR1');
	is($status, 3, 'status is 3');
}

{
	my $sigset = POSIX::SigSet->new(SIGALRM);
	sigprocmask(SIG_BLOCK, $sigset);
	alarm .2;
	ok(!defined sigtimedwait($sigset, 0.1), 'Nothing yet');

	my $ret = sigwaitinfo('ALRM');
	isa_ok($ret, 'Signal::Info', 'Return value is a hash');
	sigprocmask(SIG_UNBLOCK, $sigset);
}

{
	alarm 1;
	my $sigset = POSIX::SigSet->new(SIGUSR1);
	sigprocmask(SIG_BLOCK, $sigset);
	sigqueue($$, SIGUSR1, 42);

	my $info = sigwaitinfo($sigset);
	is($info->signo, SIGUSR1, 'Signal numer is USR1');
	is($info->value, 42, 'signal value is 42');
	is($info->pid, $$, "pid is $$");
	is($info->uid, $<, "uid is $<");

	sigqueue($$, SIGUSR1, 42);
	my $signo = sigwait($sigset);
	is($signo, SIGUSR1, 'Got SIGUSR1');
	sigprocmask(SIG_UNBLOCK, $sigset);
}

ok(!sigqueue($$, 65535), 'sigqueue return false on error');
ok($!{EINVAL}, 'Error is invalid argument');

# Invalid timeval arguments are ignored on FreeBSD
SKIP: { 
	skip 'Invalid arguments to sigwaitinfo are ignored on FreeBSD', 2 if $^O =~ /freebsd/i;
	my $sigset = POSIX::SigSet->new(SIGUSR1);
	is(sigtimedwait($sigset, -1), undef, 'sigwaitinfo returns undef on error');
	ok($!{EINVAL}, 'Error is invalid argument');
}

my $first = allocate_signal();
ok($first, 'Can allocate a signal');
my $second = allocate_signal(1);
cmp_ok($first, '>', $second, 'Priority signal is lower than normal one');
deallocate_signal($first);
is(allocate_signal, $first, 'de- and re-allocating a signal returns the same signal');

done_testing();

