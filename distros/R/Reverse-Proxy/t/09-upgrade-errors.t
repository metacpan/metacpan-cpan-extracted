use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Reverse::Proxy;

# Upgrade error paths: 501 when the server provides no psgix.io, and 502 when
# the upstream cannot be reached. (TLS/wss upstreams ARE tunnelled, reusing
# Fetch's TLS; here the TLS upstream is simply unreachable, so it 502s.)

sub upgrade_env {
	my ($extra) = @_;
	open my $in, '<', \(my $b = '');
	return {
		REQUEST_METHOD  => 'GET', PATH_INFO => '/socket', QUERY_STRING => '',
		SERVER_PROTOCOL => 'HTTP/1.1', REMOTE_ADDR => '198.51.100.9',
		HTTP_HOST       => 'front.example',
		HTTP_UPGRADE    => 'websocket',
		HTTP_CONNECTION => 'Upgrade',
		HTTP_SEC_WEBSOCKET_KEY => 'dGhlIHNhbXBsZSBub25jZQ==',
		'psgi.version'    => [1,1], 'psgi.url_scheme' => 'http',
		'psgi.input'      => $in, 'psgi.errors' => \*STDERR,
		%{ $extra || {} },
	};
}

# ---- no psgix.io -> 501 ---------------------------------------------------
{
	my $app = Reverse::Proxy->new(upstream => 'http://127.0.0.1:9')->to_app;
	my $res = $app->(upgrade_env());
	is(ref($res), 'ARRAY', 'upgrade without psgix.io returns a PSGI triplet');
	is($res->[0], 501, 'upgrade with no psgix.io gives 501');
	like($res->[2][0], qr/psgix\.io/, '501 body explains psgix.io is required');
}

# ---- unreachable (TLS) upstream -> 502 ------------------------------------
SKIP: {
	socketpair(my $PROXY_IO, my $CLIENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
		or skip "socketpair unavailable: $!", 2;

	# wss/https upstreams are tunnelled via Fetch's TLS; this one is just
	# unreachable (nothing on port 9), so the tunnel connect fails with a 502.
	my $app = Reverse::Proxy->new(upstream => 'https://127.0.0.1:9')->to_app;
	my $res = $app->(upgrade_env({ 'psgix.io' => $PROXY_IO }));
	is($res->[0], 502, 'upgrade to an unreachable TLS upstream gives 502');
	like($res->[2][0], qr/connect|upstream/i, '502 body explains the connect failure');
}

done_testing();
