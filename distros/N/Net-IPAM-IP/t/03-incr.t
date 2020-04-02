#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::IP') || print "Bail out!\n"; }

my $good = [
  { ip => '10.0.0.1', expect => '10.0.0.2', test => 'IPv4 incr' },
  { ip => '2001::1',  expect => '2001::2',  test => 'IPv6 incr' },
];

foreach my $item (@$good) {
  my $ip = Net::IPAM::IP->new( $item->{ip} );
  ok( $ip->incr->to_string eq $item->{expect}, $item->{test} );
}

my $overflow = [
  { ip => '255.255.255.255',    test => 'overflow IPv4 incr' },
  { ip => 'ffff:' x 7 . 'ffff', test => 'overflow IPv6 incr' },
];

foreach my $item (@$overflow) {
  my $ip = Net::IPAM::IP->new( $item->{ip} );
  ok( !$ip->incr, $item->{test} );
}

done_testing();
