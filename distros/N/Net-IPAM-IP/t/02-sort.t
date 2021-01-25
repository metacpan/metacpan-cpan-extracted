#!perl -T

use Test::More;

use strict;
use warnings;

BEGIN { use_ok( 'Net::IPAM::IP', qw(sort_ip) ) || print "Bail out!\n"; }

my @unsorted_str = qw(
  127.0.0.1
  0.0.0.0
  192.168.0.111
  10.0.0.1
	::
	::1
  fe80::
  fe::
  ::ffff:1.2.3.4
  255.255.255.255
  ff00::
);

my @expected = qw(
  0.0.0.0
  1.2.3.4
  10.0.0.1
  127.0.0.1
  192.168.0.111
  255.255.255.255
  ::
  ::1
  fe::
  fe80::
  ff00::
);

my @unsorted  = map { Net::IPAM::IP->new($_) } @unsorted_str;

my @sorted = sort { $a->cmp($b) } @unsorted;
is_deeply(\@sorted, \@expected, 'sort by cmp');

@sorted = sort_ip @unsorted;
is_deeply(\@sorted, \@expected, 'sort_ip');

done_testing()

