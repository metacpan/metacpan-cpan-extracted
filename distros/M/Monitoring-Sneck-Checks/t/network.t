#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use File::Path qw(make_path);
use TestServer;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::listening;
use Monitoring::Sneck::Checks::interface;

my $dir   = TestTmp::dir();
my $write = sub {
	my ( $name, $content ) = @_;
	my $path = $dir . '/' . $name;
	make_path( $path =~ s{/[^/]+\z}{}r );
	open( my $fh, '>', $path ) or die($!);
	print $fh $content;
	close($fh);
	return $path;
};
my $stand_in = sub {
	my ( $name, $code ) = @_;
	my $path = $write->( $name, '#!' . $^X . "\n" . $code );
	chmod( 0755, $path );
	return $path;
};
local $Monitoring::Sneck::Checks::base::OS        = 'linux';
local $Monitoring::Sneck::Checks::base::PROC      = $dir . '/proc';
local $Monitoring::Sneck::Checks::base::STATE_DIR = $dir . '/state';
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args, timeout => 5 );
};

# listening, the /proc/net addresses as a little endian host writes them
SKIP: {
	skip( 'the fake /proc/net is little endian', 9 ) if pack( 'L', 1 ) ne pack( 'V', 1 );
	my $header = "  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode\n";
	$write->(
		'proc/net/tcp',
		$header
			. "   0: 00000000:0016 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 1 1\n"
			. "   1: 0100007F:18EB 00000000:0000 0A 00000000:00000000 00:00000000 00000000   110        0 2 1\n"
			. "   2: 0A00A8C0:0016 0B00A8C0:D431 01 00000000:00000000 00:00000000 00000000     0        0 3 1\n"
	);
	$write->(
		'proc/net/tcp6',
		$header
			. "   0: 00000000000000000000000000000000:01BB 00000000000000000000000000000000:0000 0A 00000000:00000000 00:00000000 00000000 0 0 4 1\n"
			. "   1: 00000000000000000000000001000000:0019 00000000000000000000000000000000:0000 0A 00000000:00000000 00:00000000 00000000 0 0 5 1\n"
	);
	$write->(
		'proc/net/udp',
		$header . "   0: 00000000:0035 00000000:0000 07 00000000:00000000 00:00000000 00000000 0 0 6 2\n"
	);
	$write->( 'proc/net/udp6', $header );
	my $return = $run->(
		'listening', '-p', '22',             '-p', 'tcp/443',       '-p',
		'udp/53',    '-p', '127.0.0.1:6379', '-p', 'tcp6/[::1]:25', '-p',
		'tcp4/192.0.2.10:22'
	);
	is( $return->{code},   0,                              'listening, a wildcard counting for a address' );
	is( $return->{stdout}, "LISTENING OK - 5 listening\n", 'output, a connection not counted' );
	is(
		$run->( 'listening', '-p', 'udp/22', '-p', 'tcp4/443', '-p', '127.0.0.2:6379' )->{stdout},
		"LISTENING CRITICAL - 5 listening, udp/22 is not listened on, tcp4/443 is not listened on, 127.0.0.2:6379 is not listened on\n",
		'not listened on'
	);
	is(
		$run->( 'listening', '-o', '-p', '22', '-p', '443' )->{stdout},
		"LISTENING CRITICAL - 5 listening, also listening on tcp4/127.0.0.1:6379, tcp6/[::1]:25, udp4/0.0.0.0:53\n",
		'--only, by port'
	);
	is(
		$run->( 'listening', '-o', '-p', '22', '-p', '443', '-L' )->{stdout},
		"LISTENING CRITICAL - 5 listening, also listening on udp4/0.0.0.0:53\n",
		'--ignore-loopback'
	);
	is( $run->( 'listening', '-o', '-p', '22', '-p', '443', '-L', '-i', 'udp/53' )->{code}, 0, '--ignore' );
	is( $run->( 'listening', '-p', 'sctp/22' )->{code},                                     3, 'bad --port' );
	is( $run->( 'listening', '-p', '70000' )->{code},                                       3, 'port out of range' );
	is( $run->('listening')->{code},                                                        3, 'nothing to check' );
} ## end SKIP:
{
	local $Monitoring::Sneck::Checks::base::OS            = 'freebsd';
	local $Monitoring::Sneck::Checks::listening::SOCKSTAT = $stand_in->(
		'sockstat',
		"print <<'END';\nroot sshd 812 4 tcp46 *:22 *:*\nunbound unbound 600 3 udp4 127.0.0.1:53 *:*\nwww nginx 900 6 tcp4 192.0.2.10:443 *:*\nEND\n"
	);
	is(
		$run->( 'listening', '-p', 'tcp6/22', '-p', 'tcp4/22', '-p', '443', '-p', 'udp/127.0.0.1:53', '-o' )
			->{stdout},
		"LISTENING OK - 4 listening\n",
		'FreeBSD, tcp46 as both'
	);
}

# interface
my $nic = sub {
	my ( $name, %files ) = @_;
	$write->( 'net/' . $name . '/' . $_, $files{$_} . "\n" ) foreach keys(%files);
};
my %good = (
	operstate               => 'up',
	carrier                 => 1,
	speed                   => 1000,
	duplex                  => 'full',
	mtu                     => 9000,
	'statistics/rx_errors'  => 0,
	'statistics/tx_errors'  => 0,
	'statistics/rx_dropped' => 5,
	'statistics/tx_dropped' => 0,
);
$nic->( 'eth0', %good, device => 'x' );
$nic->( 'eth1', %good, device => 'x', operstate => 'down', carrier => 0, speed => -1, duplex => 'unknown' );
$nic->(
	'wg0',
	operstate               => 'unknown',
	carrier                 => 1,
	mtu                     => 1420,
	'statistics/rx_errors'  => 0,
	'statistics/tx_errors'  => 0,
	'statistics/rx_dropped' => 0,
	'statistics/tx_dropped' => 0
);
local $Monitoring::Sneck::Checks::interface::NET = $dir . '/net';
is(
	$run->( 'interface', '-i', 'eth0', '-s', 1000, '-F', '-m', 9000 )->{stdout},
	"INTERFACE OK - eth0 up 1000 Mb/s full\n",
	'up, at speed'
);
ok( !-e $dir . '/state', 'no state kept without a rate range' );
is(
	$run->( 'interface', '-i', 'wg0', '-r', 10 )->{stdout},
	"INTERFACE OK - wg0 up\n",
	'unknown with carrier is up, no rates the first time'
);
ok( -e $dir . '/state/interface-wg0.json', 'state kept with one' );
is(
	$run->( 'interface', '-i', 'wg0', '-r', 10 )->{stdout},
	"INTERFACE OK - wg0 up | 'wg0 errors'=0.00;;;0 'wg0 drops'=0.00;10;;0\n",
	'rates the second time'
);
is(
	$run->( 'interface', '-a' )->{stdout},
	"INTERFACE CRITICAL - eth0 up 1000 Mb/s full, eth1 is down\n",
	'--all is those with a device'
);
is( $run->( 'interface', '-a', '-x', 'eth1' )->{code}, 0, '--ignore' );
$nic->( 'eth0', speed => 100, duplex => 'half', mtu => 1500 );
is(
	$run->( 'interface', '-i', 'eth0', '-s', 1000, '-F', '-m', 9000 )->{stdout},
	"INTERFACE WARNING - eth0 up 100 Mb/s half, under 1000 Mb/s, not full duplex, MTU 1500, not 9000\n",
	'slow, half duplex, wrong MTU'
);
is(
	$run->( 'interface', '-i', 'eth0', '-e', 0 )->{stdout},
	"INTERFACE OK - eth0 up 100 Mb/s half\n",
	'no rates the first time with a range'
);
$nic->( 'eth0', 'statistics/rx_errors' => 1000000 );
like(
	$run->( 'interface', '-i', 'eth0', '-e', 0, '-E', 1 )->{stdout},
	qr/\AINTERFACE CRITICAL - eth0 up 100 Mb\/s half, [0-9.]+ errors\/s \| 'eth0 errors'=[0-9.]+;0;1;0/,
	'errors per second'
);
$nic->( 'eth0', 'statistics/rx_errors' => 0 );
is(
	$run->( 'interface', '-i', 'eth0', '-e', 0 )->{stdout},
	"INTERFACE OK - eth0 up 100 Mb/s half | 'eth0 drops'=0.00;;;0\n",
	'a counter reset has no rate'
);
is( $run->( 'interface', '-i', 'eth9' )->{stdout}, "INTERFACE CRITICAL - eth9 is not there\n", 'not there' );
is( $run->('interface')->{code},                   3,                                          'nothing to check' );
{
	local $Monitoring::Sneck::Checks::base::OS            = 'freebsd';
	local $Monitoring::Sneck::Checks::interface::IFCONFIG = $stand_in->( 'ifconfig', <<'END' );
if ( $ARGV[0] eq '-l' ) { print "em0 ix0\n"; exit 0; }
if ( $ARGV[0] eq 'em0' ) {
	print "em0: flags=8863<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500\n\tmedia: Ethernet autoselect (1000baseT <full-duplex>)\n\tstatus: active\n";
	exit 0;
}
if ( $ARGV[0] eq 'ix0' ) {
	print "ix0: flags=8863<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 9000\n\tmedia: Ethernet autoselect (10Gbase-SR <full-duplex,rxpause,txpause>)\n\tstatus: no carrier\n";
	exit 0;
}
if ( $ARGV[0] eq 'igb0' ) {
	print "igb0: flags=8863<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500\n\tmedia: Ethernet 100baseTX <half-duplex>\n\tstatus: active\n";
	exit 0;
}
if ( $ARGV[0] eq 'lagg0' ) {
	print "lagg0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500\n\tmedia: Ethernet autoselect\n\tstatus: active\n";
	exit 0;
}
print STDERR "ifconfig: interface $ARGV[0] does not exist\n";
exit 1;
END
	local $Monitoring::Sneck::Checks::interface::NETSTAT = $stand_in->( 'netstat', <<'END' );
print "Name    Mtu Network       Address              Ipkts Ierrs Idrop    Opkts Oerrs  Coll  Drop\n";
print "$ARGV[1]   1500 <Link#1>      58:9c:fc:00:00:01  100     2     3      200     4     0     5\n";
print "$ARGV[1]      - 192.0.2.0/24  192.0.2.10           90     -     -      190     -     -     -\n";
END
	is( $run->( 'interface', '-a', '-s', 1000, '-F', '-e', 0 )->{stdout},
		"INTERFACE CRITICAL - em0 up 1000 Mb/s full, ix0 is down\n", 'FreeBSD' );
	is(
		$run->( 'interface', '-i', 'em0', '-e', 0 )->{stdout},
		"INTERFACE OK - em0 up 1000 Mb/s full | 'em0 errors'=0.00;0;;0 'em0 drops'=0.00;;;0\n",
		'FreeBSD counters from netstat'
	);
	is(
		$run->( 'interface', '-i', 'igb0', '-s', 1000, '-F' )->{stdout},
		"INTERFACE WARNING - igb0 up 100 Mb/s half, under 1000 Mb/s, not full duplex\n",
		'FreeBSD media set by hand, no parens'
	);
	is( $run->( 'interface', '-i', 'lagg0' )->{stdout}, "INTERFACE OK - lagg0 up\n", 'FreeBSD lagg, no speed' );
	is( $run->( 'interface', '-i', 'em9' )->{stdout}, "INTERFACE CRITICAL - em9 is not there\n", 'FreeBSD not there' );
}

# smtp
my ( $smtp_port, $smtp_pid ) = TestServer::start(
	handler => sub {
		my ($client) = @_;
		print $client "220-mail.example.org ESMTP\r\n220 ready\r\n";
		while ( my $line = <$client> ) {
			if ( $line =~ /\AEHLO / ) {
				print $client "250-mail.example.org\r\n250-PIPELINING\r\n250-SIZE 10240000\r\n250 8BITMIME\r\n";
			} elsif ( $line =~ /\AQUIT/ ) {
				print $client "221 bye\r\n";
				last;
			} else {
				print $client "502 no\r\n";
			}
		} ## end while ( my $line = <$client> )
	}
);
my ( $refuse_port, $refuse_pid ) = TestServer::start( handler => sub { print { $_[0] } "554 go away\r\n" } );
END { kill( 'TERM', $smtp_pid, $refuse_pid ) if $smtp_pid }
my $return = $run->(
	'smtp', '-H', '127.0.0.1',  '-p', $smtp_port, '-E',
	'size', '-E', 'PIPELINING', '-e', 'ESMTP',    '-n',
	'client.example.org'
);
is( $return->{code}, 0, 'SMTP' );
like( $return->{stdout},
	qr/\ASMTP OK - 127.0.0.1:$smtp_port 220 mail.example.org ESMTP, in [0-9.]+ seconds \| time=[0-9.]+s;;;0\n\z/,
	'output' );
like(
	$run->( 'smtp', '-H', '127.0.0.1', '-p', $smtp_port, '-E', 'AUTH', '-e', 'Postfix' )->{stdout},
	qr/\ASMTP CRITICAL - .*, greeting does not have "Postfix", does not offer AUTH \|/,
	'missing extension and greeting text'
);
is(
	$run->( 'smtp', '-H', '127.0.0.1', '-p', $smtp_port, '-s' )->{stdout},
	"SMTP CRITICAL - 127.0.0.1:$smtp_port does not offer STARTTLS\n",
	'no STARTTLS'
);
is( $run->( 'smtp', '-H', '127.0.0.1', '-p', $refuse_port )->{stdout},
	"SMTP CRITICAL - 127.0.0.1:$refuse_port greeted with 554 go away\n", 'refused' );
is( $run->( 'smtp', '-H', '127.0.0.1', '-S', '-s' )->{code}, 3, '--ssl and --starttls' );

done_testing();
