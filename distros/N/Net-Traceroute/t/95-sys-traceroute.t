#!/usr/bin/perl

# Attempt some traceroutes using the system traceroute.  They aren't
# all guaranteed to work, since OS issues, parsability of traceroute,
# and network configuration all interact with this test, and we
# frequently can't predict the issues.

use strict;
use warnings;

use Test::More;

use Net::Traceroute;
use Socket;
use Sys::Hostname;

require "t/testlib.pl";

os_must_unixexec();

####

# Probe PATH, plus some well known locations, for a traceroute
# program.  skip_all this test if we can't find one.

my @path = split(":", $ENV{PATH});
my $has_traceroute;
foreach my $component (@path) {
    if(-x "$component/traceroute") {
	$has_traceroute = 1;
	last;
    }
}

if(!defined($has_traceroute)) {
    # Check for traceroute in /usr/sbin or /sbin.  The check is
    # redundant if PATH already contains one of them, but it won't hurt.
    foreach my $component ("/usr/sbin", "/sbin") {
	if(-x "$component/traceroute") {
	    $ENV{PATH} .= join(":", @path, $component);
	    goto runtest;
	}
    }

    plan skip_all => "Cannot find a traceroute executable";
}

runtest:
plan tests => 2;

####
# Get this sytem's hostname, and traceroute to it.  Don't bother
# trying localhost; its quirky on systems like netbsd.
my $name = hostname();

# Wrinkle: while our specification is that we will use whatever
# traceroute is in path, it's pretty common for testing to be done
# where there is no traceroute in path (especially automated testers).

my $tr1 = eval { Net::Traceroute->new(host => $name, timeout => 30) };
if($@) {
    die unless(exists($ENV{AUTOMATED_TESTING}));
    # If we're in an automated tester, rerun with debug => 9 so we get
    # a better clue of what's going wrong.
    $tr1 = Net::Traceroute->new(host => $name, timeout => 30, debug => 9);
}

my $packed_addr = inet_aton($name);
my $addr = inet_ntoa($packed_addr);

is($tr1->hops, 1);
is($tr1->hop_query_host(1, 0), $addr);
