#!/usr/bin/perl

use strict;
use warnings;

# Basic tests of ipv6 traceroute on a cisco.

use Test::More tests => 24;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

my @addrs = qw(
	     2001:470:8917:9:2D0:B7FF:FE5E:7F36
	     2001:470:1F06:177::1
	     2001:470:0:5D::1
	     2001:470:0:36::1
	     2001:470:0:59::2
	     2610:178:1:1:207:E9FF:FE5D:8335
	       );

my $hop = 1;
foreach my $addr (@addrs) {
    is($tr->hop_queries($hop), 3, "Hop $hop has 3 queries");
    for(my $query = 1; $query <= 3; $query++) {
	is($tr->hop_query_host($hop, $query), $addr, "Hop $hop query $query host is $addr");
    }
    $hop++;
}

__END__

Type escape sequence to abort.
Tracing the route to 2610:178:1:1:207:E9FF:FE5D:8335

  1 2001:470:8917:9:2D0:B7FF:FE5E:7F36 4 msec 0 msec 4 msec
  2 2001:470:1F06:177::1 24 msec 24 msec 28 msec
  3 2001:470:0:5D::1 20 msec 24 msec 20 msec
  4 2001:470:0:36::1 28 msec 28 msec 32 msec
  5 2001:470:0:59::2 28 msec 32 msec 28 msec
  6 2610:178:1:1:207:E9FF:FE5D:8335 28 msec 28 msec 32 msec
