#!/usr/bin/perl -w

# -----------------------------------------------------------------------------------------
# Sys::Uptime
# -----------------------------------------------------------------------------------------
# Wim De Hul 2004.
# 
# This module shows the uptime, CPUload (1, 5, 15 min average) and the number of users.
# Additionally it is also capable of returning the number of CPU's.
# 


package Sys::Uptime;
use strict;
require Exporter;
require DynaLoader;
use vars qw (@ISA $VERSION);
our @ISA = qw(Exporter DynaLoader);
$VERSION = '0.01';

# Read the load average.
sub loadavg {
	# Read the values from /proc/loadavg and put them in an array.
	open FILE, "< /proc/loadavg" or die return ("Cannot open /proc/loadavg: $!");
		my ($avg1, $avg5, $avg15, undef, undef) = split / /, <FILE>;
		my @loadavg = ($avg1, $avg5, $avg15);
	close FILE;
	return (@loadavg);
}

# Read the number of CPU's.
sub cpunbr {
	# Read the data from /proc/cpuinfo and count the lines that start with processor blablabla :-)
	open FILE, "< /proc/cpuinfo" or die return ("Cannot open /proc/cpuinfo: $!");
		my $nbrcpu = scalar grep(/^processor\s+:/,<FILE>);
	close FILE;
	return ($nbrcpu);
}

# Read the uptime.
sub uptime {
	# Read the uptime in seconds from /proc/uptime, skip the idle time...
	open FILE, "< /proc/uptime" or die return ("Cannot open /proc/uptime: $!");
		my ($uptime, undef) = split / /, <FILE>;
	close FILE;
	return ($uptime);
}

# Read the number of users.
sub users {
	# I didn't find it in /proc, so here I use the uptime output... :-)
	my $output = `uptime`;
	if (!$output) { die return ("Cannot read uptime output: $!") }
	$output =~ /[0-9]+\s+user/;
	my ($users, undef) = split /\s+/, $&;
	return ($users);
}
