use strict;
use warnings;
use Test::More qw[no_plan];
use Net::IP::Minimal qw[:PROC];

{
  my $ip = '172.16.0.216';
  ok( ip_is_ipv4( $ip ),  "$ip is IPv4" );
  is( ip_get_version( $ip ), 4, 'IPv4' );
}

{
  my $ip = 'dead:beef:89ab:cdef:0123:4567:89ab:cdef';
  ok( ip_is_ipv6( $ip ), "$ip is IPv6" );
  is( ip_get_version( $ip ), 6, 'IPv6' );
  ok( ip_is_ipv6( '::ff00:192.0.0.1' ), 'v6-encapsulated v4' );
}
