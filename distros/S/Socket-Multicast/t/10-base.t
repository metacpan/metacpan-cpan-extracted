use Test::More tests => 500;

use Socket::Multicast;
use Socket;

foreach (1..500) {
	my $multiaddr = inet_aton( rand_ip() );
	my $interface = inet_aton( rand_ip() );

	my $pack_ip_mreq = Socket::Multicast::pack_ip_mreq( $multiaddr, $interface );

	my $manual = $multiaddr . $interface;

	is( $pack_ip_mreq, $manual, "Packed structures match" );
}

sub rand_ip {
	return join '.', map { int rand 255 } (1..4);
}
