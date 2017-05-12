#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 4;

use Net::IP::XS qw(ip_normalize);

my @res = ip_normalize('1.2.3.0/24k');
is($Net::IP::XS::ERRNO, 172,
    "Got correct error number");
is($Net::IP::XS::ERROR, "Invalid prefix length /24k",
    "Got correct error message");

@res = ip_normalize('2001:2000::/33k');
is($Net::IP::XS::ERRNO, 172,
    "Got correct error number");
is($Net::IP::XS::ERROR, "Invalid prefix length /33k",
    "Got correct error message");

1;
