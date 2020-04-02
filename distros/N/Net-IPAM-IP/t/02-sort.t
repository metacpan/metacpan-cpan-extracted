#!perl -T

use Test::More;

use strict;
use warnings;

BEGIN { use_ok('Net::IPAM::IP')             || print "Bail out!\n"; }

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

my @unsorted;
foreach my $addr (@unsorted_str) {
	my $ip;
	ok($ip = Net::IPAM::IP->new($addr), $addr);
	push @unsorted, $ip;
}

my @sorted;
foreach my $ip ( sort { $a->cmp($b) } @unsorted ) {
  push @sorted, $ip->to_string;
}

is_deeply(\@sorted, \@expected, 'sort by cmp');

done_testing()

