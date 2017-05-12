#!/usr/bin/perl -w

# vim: set ft=perl:

use strict;
use Test::More tests => 2;
my ($res, @res);

use_ok("Net::Nslookup");

$res = nslookup(host => "66.151.183.151", type => "PTR");
is($res, "ironmail1.boston.com", "nslookup(host => '66.151.183.151', type => PTR) -> ironmail1.boston.com");

