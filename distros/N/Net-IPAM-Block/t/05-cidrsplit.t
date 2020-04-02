#!perl -T

use Test::More;

use strict;
use warnings;

BEGIN { use_ok( 'Net::IPAM::Block' ) || print "Bail out!\n"; }

my $must_fail = [
  { cidr => '10.0.0.1-10.0.0.6', test => 'IPv4 range, must fail' },
  { cidr => '2001::1-2001::2',   test => 'IPv6 range, must fail' },
  { cidr => '134.60.0.0',        test => 'IPv4 addr, must fail' },
  { cidr => '2001:7c0:900::1',   test => 'IPv6 addr, must fail' },
];

my @cidrs;
foreach my $item (@$must_fail) {
  ok(! Net::IPAM::Block->new( $item->{cidr} )->cidrsplit, $item->{test});
}

my $must_pass = [
  {
    cidr   => '10.0.0.0/32',
    expect => [],
    test   => 'IPv4 /32,  max cidr mask returns undef'
  },
  {
    cidr   => '::/128',
    expect => [],
    test   => 'IPv6 /128, max cidr mask returns undef'
  },

  {
    cidr   => '0.0.0.0/0',
    expect => [ '0.0.0.0/1', '128.0.0.0/1' ],
    test   => "edge case, 0.0.0.0/0  -> [ '0.0.0.0/1',  '128.0.0.0/1' ]"
  },
  {
    cidr   => '0.0.0.0/31',
    expect => [ '0.0.0.0/32', '0.0.0.1/32' ],
    test   => "edge case, 0.0.0.0/31 -> [ '0.0.0.0/32', '0.0.0.1/32' ]"
  },
  {
    cidr   => '255.255.255.254/31',
    expect => [ '255.255.255.254/32', '255.255.255.255/32' ],
    test   => "edge case, 255.255.255.254/31 -> [ '255.255.255.254/32', '255.255.255.255/32' ]"
  },
  {
    cidr   => '10.0.0.0/8',
    expect => [ '10.0.0.0/9', '10.128.0.0/9' ],
    test   => "split     10.0.0.0/8 -> [ '10.0.0.0/9',  '10.128.0.0/9' ]"
  },

  {
    cidr   => '::/0',
    expect => [ '::/1', '8000::/1' ],
    test   => "edge case, ::/0      -> [ '::/1',       '8000::/1' ]"
  },
  {
    cidr   => '::/127',
    expect => [ '::/128', '::1/128' ],
    test   => "edge case, ::/127    -> [ '::/128',     '::1/128' ]"
  },
  {
    cidr   => 'fe80::/12',
    expect => [ 'fe80::/13', 'fe88::/13' ],
    test   => "split      fe80::/12 -> [ 'fe80::/13', 'fe88::/13']"
  },
];

foreach my $item (@$must_pass) {
  @cidrs = map { defined $_ ? $_->to_string : () } Net::IPAM::Block->new( $item->{cidr} )->cidrsplit;
  is_deeply(\@cidrs, $item->{expect}, $item->{test});
}

my $split = Net::IPAM::Block->new('fe80::/12')->cidrsplit;
my $cidr1 = Net::IPAM::Block->new('fe80::/13');
my $cidr2 = Net::IPAM::Block->new('fe88::/13');

is_deeply($split, [$cidr1, $cidr2], 'wantarray');

done_testing();

