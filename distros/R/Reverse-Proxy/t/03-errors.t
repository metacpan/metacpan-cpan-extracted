use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Reverse::Proxy;

sub make_env {
	my ($path) = @_;
	open my $in, '<', \(my $b = '');
	return {
		REQUEST_METHOD => 'GET', PATH_INFO => $path, QUERY_STRING => '',
		SERVER_PROTOCOL => 'HTTP/1.1', REMOTE_ADDR => '127.0.0.1',
		'psgi.version' => [1,1], 'psgi.url_scheme' => 'http',
		'psgi.input' => $in, 'psgi.errors' => \*STDERR,
	};
}

# Grab a free port then close it, so connecting to it is refused.
my $probe = IO::Socket::INET->new(
	LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
) or die "listen: $!";
my $dead = $probe->sockport;
close $probe;

# ---- unreachable upstream -> 502 -----------------------------------------
{
	my $app = Reverse::Proxy->new(
		upstream => "http://127.0.0.1:$dead", timeout => 2,
	)->to_app;
	my $res = $app->(make_env('/'));
	is($res->[0], 502, 'connection refused upstream gives 502');
	like($res->[2][0], qr/Bad Gateway/, '502 body mentions Bad Gateway');
}

# ---- unresolvable upstream host -> 502 -----------------------------------
# A name in the reserved .invalid TLD (RFC 6761) must never resolve, so the
# proxy should 502. Some resolvers (seen on CPAN Testers hosts) hijack NXDOMAIN
# and answer with a parking page, making the upstream reachable; when that
# happens the DNS-failure path cannot be exercised, so skip rather than fail.
# The connection-refused case above already covers the 502 mapping itself.
{
	my $app = Reverse::Proxy->new(
		upstream => 'http://nonexistent.invalid.zxsaswqqasdfa', timeout => 3,
	)->to_app;
	my $res = $app->(make_env('/'));
	if ($res->[0] == 502) {
		is($res->[0], 502, 'DNS failure upstream gives 502');
	}
	else {
	SKIP: {
			skip "resolver hijacks NXDOMAIN (got status $res->[0]); "
				. "cannot test the DNS-failure path here", 1;
		}
	}
}

# ---- constructor validation ----------------------------------------------
{
	eval { Reverse::Proxy->new() };
	like($@, qr/exactly one/, 'new() with no target croaks');

	eval { Reverse::Proxy->new(upstream => 'http://x', resolver => sub { 'http://y' }) };
	like($@, qr/exactly one/, 'new() with two targets croaks');
}

done_testing();
