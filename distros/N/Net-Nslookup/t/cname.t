#!/usr/bin/perl -w

# vim: set ft=perl:

use strict;
use Test::More tests => 2;
my ($res, @res);

use_ok("Net::Nslookup");

# Get CNAME record
$res = nslookup(host => "ctest.boston.com", type => "CNAME");
is($res, "www.boston.com", "nslookup(host => 'ctest.boston.com', type => CNAME) -> www.boston.com");

