#! /usr/bin/perl

use 5.012;
use warnings;
use Config;

use POSIX::RT::Clock;
use POSIX::RT::Timer;

my %clocks = map { $_ => POSIX::RT::Clock->new($_) } POSIX::RT::Clock->get_clocks;
$clocks{per_process} = POSIX::RT::Clock->get_cpuclock(getppid) if POSIX::RT::Clock->can('get_cpuclock');
$clocks{per_thread}  = eval { require threads; POSIX::RT::Clock->get_cpuclock(threads->self) } if $Config{usethreads};

while (my ($name, $clock) = each %clocks) {
	my $success = eval { $clock->timer(signal => 'USR1') } ? 1 : 0;
	say "$name: $success";
}

