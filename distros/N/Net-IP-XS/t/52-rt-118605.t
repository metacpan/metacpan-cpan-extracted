#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 1;

use Config;
use Math::BigInt;
use Net::IP::XS qw(ip_splitprefix);

my $large_len = Math::BigInt->new(1)->blsft(4096)->bmul(-1);
my @res = ip_splitprefix("1.2.3.4/$large_len");
is_deeply(\@res, [], 'No result when length unable to be parsed');

1;
