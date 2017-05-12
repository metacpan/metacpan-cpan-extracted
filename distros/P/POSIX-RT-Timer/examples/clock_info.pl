#! /usr/bin/perl

use strict;
use warnings;

use POSIX::RT::Clock;

for my $clock_name (POSIX::RT::Clock->get_clocks) {
	my $clock = POSIX::RT::Clock->new($clock_name);
	printf "Clock = %s, Time = %.3fs, precision = %dns\n", $clock_name, $clock->get_time, $clock->get_resolution * 1_000_000_000;
}
