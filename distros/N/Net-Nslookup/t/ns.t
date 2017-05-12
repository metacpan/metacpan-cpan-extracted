#!/usr/bin/perl -w

# vim: set ft=perl:

use strict;
use Test::More tests => 9;
my ($res, @res);

use_ok("Net::Nslookup");

@res = nslookup(domain => "boston.com", type => "NS");
@res = sort @res;
is($res[0], "ns1.p22.dynect.net", "nslookup(domain => 'boston.com', type => NS) -> ns1.p22.dynect.net");
is($res[1], "ns2.p22.dynect.net", "nslookup(domain => 'boston.com', type => NS) -> ns2.p22.dynect.net");
is($res[2], "ns3.p22.dynect.net", "nslookup(domain => 'boston.com', type => NS) -> ns3.p22.dynect.net");
is($res[3], "ns4.p22.dynect.net", "nslookup(domain => 'boston.com', type => NS) -> ns4.p22.dynect.net");

@res = nslookup(domain => "boston.com", type => "NS", recurse => 1);
@res = sort @res;

is($res[0], "204.13.250.22", "nslookup(domain => 'boston.com', type => NS, recurse => 1) -> 204.13.250.22");
is($res[1], "204.13.251.22", "nslookup(domain => 'boston.com', type => NS, recurse => 1) -> 204.13.251.22");
is($res[2], "208.78.70.22", "nslookup(domain => 'boston.com', type => NS, recurse => 1) -> 208.78.70.22");
is($res[3], "208.78.71.22", "nslookup(domain => 'boston.com', type => NS, recurse => 1) -> 208.78.71.22");

