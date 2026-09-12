#!perl

use strict;
use warnings;

use Test::More tests => 47;

BEGIN {
    use_ok( 'NetAddr::MAC', qw( :properties ) )
      or die "# NetAddr::MAC not available\n";
}

# RFC 1112 s6.4: 01-00-5E plus the low 23 bits of the group address
my @ipv4_multicast = qw(
  01-00-5e-00-00-01
  01-00-5e-00-00-12
  01-00-5e-7f-ff-ff
  0100.5e00.0001
  01005e000001
);

# just outside the 23 bit window, or wrong OUI
my @not_ipv4_multicast = qw(
  01-00-5e-80-00-00
  01-00-5e-ff-ff-ff
  01-00-5f-00-00-01
  00-00-5e-00-01-01
  33-33-00-00-00-01
  01-00-5e-00-00-01-00-00
);

# RFC 2464 s7: 33-33 plus the low 32 bits of the group address
my @ipv6_multicast = qw(
  33-33-00-00-00-01
  33-33-ff-e8-65-8f
  33:33:00:00:00:fb
  3333.0000.0001
  333300000001
);

my @not_ipv6_multicast = qw(
  33-32-00-00-00-01
  32-33-00-00-00-01
  01-00-5e-00-00-01
  33-33-00-00-00-01-00-00
);

for my $mac (@ipv4_multicast) {
    ok( mac_is_ipv4_multicast($mac),  'ipv4 multicast identified from ' . $mac );
    ok( !mac_is_ipv6_multicast($mac), 'ipv6 multicast = false from ' . $mac );
    ok( mac_is_multicast($mac),       'group bit set on ' . $mac );
}

for my $mac (@not_ipv4_multicast) {
    ok( !mac_is_ipv4_multicast($mac), 'ipv4 multicast = false from ' . $mac );
}

for my $mac (@ipv6_multicast) {
    ok( mac_is_ipv6_multicast($mac),  'ipv6 multicast identified from ' . $mac );
    ok( !mac_is_ipv4_multicast($mac), 'ipv4 multicast = false from ' . $mac );
    ok( mac_is_multicast($mac),       'group bit set on ' . $mac );
}

for my $mac (@not_ipv6_multicast) {
    ok( !mac_is_ipv6_multicast($mac), 'ipv6 multicast = false from ' . $mac );
}

# object interface
my $v4 = NetAddr::MAC->new('01:00:5e:00:00:12');
ok( $v4->is_ipv4_multicast,  'object: 01:00:5e:00:00:12 is ipv4 multicast' );
ok( !$v4->is_ipv6_multicast, 'object: 01:00:5e:00:00:12 is not ipv6 multicast' );
ok( !$v4->is_vrrp,           'object: 01:00:5e:00:00:12 is not a vrrp virtual router address' );

my $v6 = NetAddr::MAC->new('33:33:ff:e8:65:8f');
ok( $v6->is_ipv6_multicast,  'object: 33:33:ff:e8:65:8f is ipv6 multicast' );
ok( !$v6->is_ipv4_multicast, 'object: 33:33:ff:e8:65:8f is not ipv4 multicast' );

# eui64 is never either
my $e64 = NetAddr::MAC->new('33:33:00:00:00:01:00:00');
ok( !$e64->is_ipv6_multicast, 'object: eui64 is never ipv6 multicast' );
