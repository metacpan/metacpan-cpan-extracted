#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;
use List::Util qw(shuffle);

BEGIN {
  use_ok('Net::IPAM::Block')
    || print "Bail out!\n";
}

can_ok( 'Net::IPAM::Block', 'new' );

# sorted
my @input = (
  "0.0.0.0/0",
  "10.0.0.0/9",
  "10.0.0.0/11",
  "10.32.0.0/11",
  "10.64.0.0/11",
  "10.96.0.0/11",
  "10.96.0.0/13",
  "10.96.0.2-10.96.1.17",
  "10.104.0.0/13",
  "10.112.0.0/13",
  "10.120.0.0/13",
  "10.128.0.0/9",
  "134.60.0.0/16",
  "193.197.62.192/29",
  "193.197.64.0/22",
  "193.197.228.0/22",
  "::/0",
  "::-::fffe",
  "2001:7c0:900::/48",
  "2001:7c0:900::/49",
  "2001:7c0:900::/52",
  "2001:7c0:900::/53",
  "2001:7c0:900:800::/56",
  "2001:7c0:900:800::/64",
  "2001:7c0:900:1000::/52",
  "2001:7c0:900:1000::/53",
  "2001:7c0:900:1800::/53",
  "2001:7c0:900:8000::/49",
  "2001:7c0:900:8000::/56",
  "2001:7c0:900:8100::/56",
  "2001:7c0:2330::/44",
);

my @blocks;
foreach my $b ( shuffle @input ) {
  push @blocks, Net::IPAM::Block->new($b) // fail("wrong format: $b");
}

my @sorted = map { $_->to_string }
  sort { $a->cmp($b) } @blocks;

is_deeply( \@input, \@sorted, 'sort with cmp()' );

#diag explain \@sorted;
done_testing();
