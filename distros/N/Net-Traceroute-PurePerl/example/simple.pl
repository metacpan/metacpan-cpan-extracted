#!/usr/bin/perl

use strict;
use Net::Traceroute::PurePerl;

my $host = $ARGV[0] || 'www.perl.org';

my $t = new Net::Traceroute::PurePerl(
      host             => $host,
      debug            => 0,
      max_ttl          => 20,
      timeout          => 2,
      protocol         => 'icmp',
      concurrent_hops  => 6,
);

$t->traceroute;
$t->pretty_print;

