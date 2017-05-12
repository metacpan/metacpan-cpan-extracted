
use Socket;
use Test::More;
use Socket::Multicast6 qw/:ipv4/;

unless (defined eval("IP_ADD_SOURCE_MEMBERSHIP")) {
	plan skip_all => "Source Specific Multicast isn't available on this system.";
} else {
	plan tests => 100;
}


foreach (1..100) {
	my $multiaddr = inet_aton( rand_ip() );
	my $sourceaddr = inet_aton( rand_ip() );
	my $interface = inet_aton( rand_ip() );

	my $pack_ip_mreq = pack_ip_mreq_source( $multiaddr, $sourceaddr, $interface );

	my $manual = $multiaddr . $interface . $sourceaddr;

	is( $pack_ip_mreq, $manual, "Packed structures match" );
}


sub rand_ip {
	return join '.', map { int rand 255 } (1..4);
}
