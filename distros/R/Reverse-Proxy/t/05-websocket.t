use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use IO::Handle;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Reverse::Proxy;

# WebSocket/Upgrade tunnelling. We stand in for the server's psgix.io with one
# end of a socketpair; a forked "client" holds the other end. The backend does
# the 101 handshake and echoes. The proxy should: forward the Upgrade request,
# relay the upstream 101 to the client, then splice bytes both ways.

# ---- upstream: 101 + echo ------------------------------------------------
sub spawn_backend {
	my $srv = IO::Socket::INET->new(
		LocalHost => '127.0.0.1', LocalPort => 0, Listen => 4, ReuseAddr => 1,
	) or die "listen: $!";
	my $port = $srv->sockport;
	my $pid  = fork // die "fork: $!";
	if (!$pid) {
		my $c = $srv->accept or exit 1;
		$c->autoflush(1);
		my %h;
		my $reqline = <$c>;
		while (my $l = <$c>) { $l =~ s/\r\n$//; last if $l eq '';
			my ($k, $v) = split /:\s*/, $l, 2; $h{ lc $k } = $v }
		# echo back a marker header so the client can verify pass-through
		syswrite($c, "HTTP/1.1 101 Switching Protocols\r\n"
			. "Upgrade: websocket\r\nConnection: Upgrade\r\n"
			. "Sec-WebSocket-Accept: " . ($h{'sec-websocket-key'} // 'none') . "\r\n"
			. "X-Upstream-Saw-XFF: " . ($h{'x-forwarded-for'} // '') . "\r\n\r\n");
		while (1) { my $r = sysread($c, my $b, 4096); last unless $r; syswrite($c, $b) }
		close $c;
		exit 0;
	}
	return ($pid, $port);
}

my ($bpid, $bport) = spawn_backend();
select undef, undef, undef, 0.2;

# socketpair: PROXY_IO is handed to the proxy as psgix.io; CLIENT is the peer.
socketpair(my $PROXY_IO, my $CLIENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
	or die "socketpair: $!";
$_->autoflush(1) for $PROXY_IO, $CLIENT;

# ---- forked client: read 101, exchange a frame, then close ---------------
my $cpid = fork // die "fork: $!";
if (!$cpid) {
	close $PROXY_IO;
	my $hdr = '';
	while (index($hdr, "\r\n\r\n") < 0) {
		my $r = sysread($CLIENT, my $b, 1024); last unless $r; $hdr .= $b;
	}
	syswrite($CLIENT, "PING-PAYLOAD");
	my $echo = '';
	while (length($echo) < length('PING-PAYLOAD')) {
		my $r = sysread($CLIENT, my $b, 64); last unless $r; $echo .= $b;
	}
	close $CLIENT;
	my $ok = ($hdr =~ m{^HTTP/1\.1 101\b})
		&& ($hdr =~ /X-Upstream-Saw-XFF: 198\.51\.100\.9/)
		&& ($echo eq 'PING-PAYLOAD');
	exit($ok ? 0 : 1);
}
close $CLIENT;

# ---- run the proxy tunnel (blocks until the client closes) ---------------
my $app = Reverse::Proxy->new(upstream => "http://127.0.0.1:$bport")->to_app;
my $env = {
	REQUEST_METHOD  => 'GET',
	PATH_INFO       => '/socket',
	QUERY_STRING    => '',
	SERVER_PROTOCOL => 'HTTP/1.1',
	REMOTE_ADDR     => '198.51.100.9',
	HTTP_HOST       => 'front.example',
	HTTP_UPGRADE    => 'websocket',
	HTTP_CONNECTION => 'Upgrade',
	HTTP_SEC_WEBSOCKET_KEY     => 'dGhlIHNhbXBsZSBub25jZQ==',
	HTTP_SEC_WEBSOCKET_VERSION => '13',
	'psgi.version'    => [1,1],
	'psgi.url_scheme' => 'http',
	'psgix.io'        => $PROXY_IO,
	'psgi.errors'     => \*STDERR,
};

my $res = $app->($env);
is(ref($res), 'ARRAY', 'tunnel returns a (benign) PSGI response after hijack');

waitpid $cpid, 0;
is($? >> 8, 0,
	'client received the 101 (with forwarded XFF) and its frame was echoed back through the tunnel');

END { if ($bpid) { local $?; kill 'TERM', $bpid; waitpid $bpid, 0 } }

done_testing();
