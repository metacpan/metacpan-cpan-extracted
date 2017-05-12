#!/usr/bin/perl -w

# vim: set ft=perl:

use strict;
use Test::More tests => 5;
my ($res, @res);

use_ok("Net::Nslookup");

@res = nslookup(domain => "boston.com", type => "MX");
@res = sort @res;
is($res[0], "bghqmail.globe.com", "nslookup(domain => 'boston.com', type => MX) -> bghqmail.globe.com");
is($res[1], "inapmail.boston.com", "nslookup(domain => 'boston.com', type => MX) -> inapmail.boston.com");

@res = nslookup(domain => "boston.com", type => "MX", recurse => 1);
@res = sort @res;
is($res[0], "50.203.72.25", "nslookup(domain => 'boston.com', type => MX, recurse => 1) -> 50.203.72.25");
is($res[1], "66.151.183.181", "nslookup(domain => 'boston.com', type => MX, recurse => 1) -> 66.151.183.181");
