#!/usr/local/bin/perl -w
#
# $Id: traffic.pl,v 1.1.1.1 2003/12/18 01:16:52 toni Exp $
#
# A simple application to query the in/out octet counts on all interfaces
# on a set of routers, and sum up the total bytes of traffic carried.
#
# Note that this example does not really work as it doesn't take into
# account wrapped counters or skew across responses.  But the basic idea
# is sound.
#
use strict;
use Carp;

use SNMP::Multi;

my $read_comm   = 'Super!Secret';
my @all_routers = qw/ router01.my.com router02.my.com router03.my.com
		      router04.my.com router05.my.com /;

my $sm = SNMP::Multi->new(
    Method    => 'bulkwalk',
    Community => $read_comm,
    Requests  => SNMP::Multi::VarReq->new(
	hosts => [ @all_routers ],
	vars  => [ [ 'ifOutOctets' ], [ 'ifInOctets' ] ],
    ),
) or croak "$SNMP::Multi::error\n";

my $resp = $sm->execute() or croak $sm->error();

my $sum = 0;
grep { $sum += ($_ ? $_ : 0) } $resp->values();

print "Total traffic: $sum bytes.\n";
exit 0;
