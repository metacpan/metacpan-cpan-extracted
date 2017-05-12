#!perl

use strict;
use warnings;
use Test::More 0.98;

use Regexp::IPv4 qw($IPv4_re);

ok("127.0.0.1" =~ /^$IPv4_re$/);
ok("255.255.255.255" =~ /^$IPv4_re$/);
ok("255.255.255.256" !~ /^$IPv4_re$/);
ok("355.255.255.256" !~ /^$IPv4_re$/);

done_testing;
