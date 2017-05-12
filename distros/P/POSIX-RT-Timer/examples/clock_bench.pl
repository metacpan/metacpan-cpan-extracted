#! perl

use strict;
use warnings;

use Benchmark qw/cmpthese :hireswallclock/;
use Time::HiRes qw/clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC/;
use POSIX::RT::Clock;

my $clock = POSIX::RT::Clock->new;
my $fastclock = POSIX::RT::Clock->new('realtime_coarse');
my $hires = CLOCK_REALTIME;

cmpthese(2000000, {
	'time-hires'    => sub { clock_gettime($hires) },
	'rt-timer'      => sub { $clock->get_time },
	'rt-timer-fast' => sub { $fastclock->get_time },
});

$clock = POSIX::RT::Clock->new('monotonic');
$fastclock = POSIX::RT::Clock->new('monotonic_coarse');
$hires = CLOCK_MONOTONIC;

cmpthese(2000000, {
	'time-hires'    => sub { clock_gettime($hires) },
	'rt-timer'      => sub { $clock->get_time },
	'rt-timer-fast' => sub { $fastclock->get_time },
});
