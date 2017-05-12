use Test::More tests => 5;

use Socket;
use Socket6;
use Socket::Multicast6;


my @IPV6_MCAST_ADDRS = (
	'ff01::0',
	'ff02::1',
	'ff05::1:3',
	'ff1e:4838:dead::beef',
	'ff78:140:2001:630:d0:f000:feed:80',
);	


foreach my $addr (@IPV6_MCAST_ADDRS) {
	my $multiaddr = inet_pton( AF_INET6, $addr );
	my $interface = int rand(255);

	my $pack_ip_mreq = Socket::Multicast6::pack_ipv6_mreq( $multiaddr, $interface );

	my $manual = $multiaddr . pack('I',$interface);

	is( $pack_ip_mreq, $manual, "Packed structures match" );
}
