#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::wireguard;

# the fake wg prints t/data/wireguard/$WIREGUARD_TEST_SET/output, handshakes in it relative to now
local $Monitoring::Sneck::Checks::wireguard::WG = $FindBin::Bin . '/data/wireguard/wg';
my $run = sub {
	my ( $set, @args ) = @_;
	local $ENV{WIREGUARD_TEST_SET} = $set;
	return Monitoring::Sneck::Checks->run( check => 'wireguard', args => \@args );
};

my $site = 'wg0 10.0.0.2/32, endpoint 192.0.2.10:51820, handshake 4[56] seconds ago, received 123456 B, sent 654321 B';
my $laptop = 'wg0 10.0.0.3/32, endpoint 198.51.100.7:40123, handshake 10[01] seconds ago, received 1000 B, sent 2000 B';
my $offsite = 'wg1 OFFSITEp, endpoint 203.0.113.5:51821, handshake (?:90|91) seconds ago, received 5000 B, sent 6000 B';

my $return = $run->('ok');
like(
	$return->{stdout},
	qr/\AWIREGUARD OK - 3 peers ok \| peers=3;;;0 stale=0;;;0\n$site\n$laptop\n$offsite\n\z/,
	'all recent, named by allowed IP or key'
);
unlike( $return->{combined}, qr/PRIV|PSK/, 'private and preshared keys never output' );
like(
	$run->( 'ok', '-i', 'wg1', '-i', 'wg9' )->{stdout},
	qr/\AWIREGUARD CRITICAL - wg9 is not there, 1 other ok \| peers=1;;;0 stale=0;;;0\n$offsite\n\z/,
	'--interface, one not there'
);
like(
	$run->(
		'ok',                                           '-p',
		'SITEpubAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0=', '-p',
		'GONEpubAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0='
	)->{stdout},
	qr/\AWIREGUARD CRITICAL - peer GONEpubA is not there, 1 other ok \| peers=1;;;0 stale=0;;;0\n$site\n\z/,
	'--peer, one not there'
);
like(
	$run->( 'ok', '-w', '60' )->{stdout},
	qr/\AWIREGUARD WARNING - wg0 10\.0\.0\.3\/32 handshake 10[01] seconds ago, wg1 OFFSITEp handshake (?:90|91) seconds ago, 1 other ok \| peers=3;;;0 stale=2;;;0\n/,
	'over --warning'
);

like(
	$run->('stale')->{stdout},
	qr/\AWIREGUARD CRITICAL - wg0 10\.0\.0\.2\/32 handshake 60[01] seconds ago, wg0 10\.0\.0\.3\/32 never handshaken, 1 other ok \|.*\nwg0 10\.0\.0\.3\/32, endpoint \(none\), never handshaken,/s,
	'stale and never handshaken'
);
like(
	$run->( 'stale', '-k' )->{stdout},
	qr/\AWIREGUARD WARNING - wg0 10\.0\.0\.2\/32 handshake 60[01] seconds ago \| peers=1;;;0 stale=1;;;0\n/,
	'--keepalive leaves out idle peers'
);
is(
	$run->( 'stale', '-k', '-i', 'wg0', '-p', 'PHONEpubAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0=' )->{stdout},
	"WIREGUARD OK - no peers to check\n",
	'nothing left to check'
);

is( $run->('none')->{stdout}, "WIREGUARD OK - no WireGuard interfaces\n", 'no interfaces' );
is(
	$run->('denied')->{stdout},
	"WIREGUARD UNKNOWN - wg show exited 1, Unable to access interface: Operation not permitted\n",
	'not root'
);
{
	local $Monitoring::Sneck::Checks::wireguard::WG = $FindBin::Bin . '/data/wireguard/nope';
	like( $run->('ok')->{stdout}, qr/\AWIREGUARD UNKNOWN - \S+nope is not there\n\z/, 'wg not there' );
}

done_testing();
