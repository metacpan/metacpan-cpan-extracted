#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::IP') || print "Bail out!\n"; }
can_ok('Net::IPAM::IP', 'getname');
can_ok('Net::IPAM::IP', 'getaddrs');

my @ips = Net::IPAM::IP->getaddrs('localhost.', sub{});
SKIP: {
  skip 'no DNS resolution, maybe no network connection', 2 unless @ips;
  ok(@ips = Net::IPAM::IP->getaddrs('dns.google.'), 'getaddrs for dns.google.');
	my $ip = shift @ips;
  ok($ip->getname eq 'dns.google', "getname($ip) is dns.google");
}

done_testing();
