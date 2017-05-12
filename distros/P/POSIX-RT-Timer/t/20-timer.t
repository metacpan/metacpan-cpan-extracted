#!perl

use strict;
use warnings;
use Test::More tests => 14;

use Time::HiRes qw/alarm sleep/;
use POSIX::RT::Clock;
use POSIX::RT::Timer;
use POSIX qw/SIGUSR1 pause/;

{
	alarm 0.2;

	my $got_signal;
	local $SIG{USR1} = sub {
		$got_signal = 1;
	};

	my $timer = POSIX::RT::Timer->new(signal => SIGUSR1, value => 0.1);

	pause while !$got_signal;
	is($got_signal, 1, 'Got signal');

	alarm 0;
}

{
	alarm 0.2;

	my $got_signal;
	local $SIG{USR1} = sub {
		$got_signal = 1;
	};

	my $timer = POSIX::RT::Timer->new(clock => 'realtime', signal => SIGUSR1, value => 0.1);

	pause while !$got_signal;
	is($got_signal, 1, 'Got signal');

	alarm 0;
}

my $hasmodules = eval { require POSIX::RT::Signal; require Signal::Mask; POSIX::RT::Signal->VERSION(0.009) };

{
	alarm 2;
	my ($counter, $compare, $expected) = (0, 3, 3);

	my $timer = POSIX::RT::Timer->new(signal => SIGUSR1, value => 0.1, interval => 0.1, ident => 42);
	
	local $SIG{USR1} = sub {
		is ++$counter, $_, "$counter == $_";
	};

	pause for 1..3;

	alarm 0;

	SKIP: {
		skip 'POSIX::RT::Signal or Signal::Mask not installed', 6 if not $hasmodules;
		no warnings 'once';
		local $Signal::Mask{USR1} = 1;
		$expected += 3;
		for (4..6) {
			my $result = POSIX::RT::Signal::sigwaitinfo(SIGUSR1, 1);
			is($counter++, $compare++, 'Counter equals compare');
			is $result->{value}, 42, 'identifier is 42';
		}
	}

	$timer->set_timeout(0, 0);

	is($counter, $expected, 'Counter equals expected');

	my $got_signal = 0;
	local $SIG{USR1} = sub {
		$got_signal++;
	};

	sleep .2;

	is($got_signal, 0, 'Shouldn\'t get a signal');
};

{
	alarm 0.2;

	my $got_signal = 0;
	local $SIG{USR1} = sub {
		$got_signal++;
	};

	my $timer = POSIX::RT::Clock->new('realtime')->timer(signal => SIGUSR1, value => 0.1);

	pause while !$got_signal;
	is($got_signal, 1, 'Got signal via clock');

	alarm 0;
}
