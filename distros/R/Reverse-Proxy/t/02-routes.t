use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Reverse::Proxy;

# Backend labelled by $tag, echoing "TAG=... U=<uri>" so we can tell which
# upstream served the request and what forwarded path it saw.
sub spawn_backend {
	my ($tag) = @_;
	my $srv = IO::Socket::INET->new(
		LocalHost => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1,
	) or die "listen: $!";
	my $port = $srv->sockport;
	my $pid  = fork // die "fork: $!";
	if (!$pid) {
		while (my $c = $srv->accept) {
			$c->autoflush(1);
			my $line = <$c>; $line = '' unless defined $line; $line =~ s/\r\n$//;
			my (undef, $uri) = split /\s+/, $line;
			while (my $h = <$c>) { $h =~ s/\r\n$//; last if $h eq '' }
			my $out = "TAG=$tag U=$uri";
			print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
				. "Content-Length: " . length($out) . "\r\nConnection: close\r\n\r\n$out";
			close $c;
		}
		exit 0;
	}
	return ($pid, $port);
}

sub make_env {
	my ($path, $qs) = @_;
	open my $in, '<', \(my $b = '');
	return {
		REQUEST_METHOD => 'GET', PATH_INFO => $path,
		QUERY_STRING => defined $qs ? $qs : '',
		SERVER_PROTOCOL => 'HTTP/1.1', REMOTE_ADDR => '127.0.0.1',
		'psgi.version' => [1,1], 'psgi.url_scheme' => 'http',
		'psgi.input' => $in, 'psgi.errors' => \*STDERR,
	};
}

my ($apid, $aport) = spawn_backend('api');
my ($wpid, $wport) = spawn_backend('web');
select undef, undef, undef, 0.2;

my $app = Reverse::Proxy->new(
	routes => [
		'/api' => "http://127.0.0.1:$aport",
		'/'    => "http://127.0.0.1:$wport",   # catch-all
	],
)->to_app;

# /api/users -> api backend, prefix stripped to /users
{
	my $res = $app->(make_env('/api/users', 'x=1'));
	is($res->[0], 200, '/api/users routed');
	like($res->[2][0], qr/\bTAG=api\b/,        'went to the api upstream');
	like($res->[2][0], qr{\bU=/users\?x=1\b},  '/api prefix stripped from forwarded path');
}

# /about -> catch-all web backend, path unchanged
{
	my $res = $app->(make_env('/about'));
	is($res->[0], 200, '/about routed');
	like($res->[2][0], qr/\bTAG=web\b/,   'went to the catch-all web upstream');
	like($res->[2][0], qr{\bU=/about\b},  'path preserved for catch-all');
}

# exact prefix match: /api itself -> api backend, path becomes /
{
	my $res = $app->(make_env('/api'));
	like($res->[2][0], qr/\bTAG=api\b/,  'exact /api matches the api route');
	like($res->[2][0], qr{U=/(?:\s|$)},  'forwarded path is / for a bare prefix');
}

# non-boundary: /apix must NOT match /api (falls through to catch-all)
{
	my $res = $app->(make_env('/apix'));
	like($res->[2][0], qr/\bTAG=web\b/,  '/apix does not match /api prefix');
}

# no matching route -> 404 (routes with no catch-all)
{
	my $strict = Reverse::Proxy->new(
		routes => [ '/api' => "http://127.0.0.1:$aport" ],
	)->to_app;
	my $res = $strict->(make_env('/nope'));
	is($res->[0], 404, 'unmatched path with no catch-all gives 404');
}

END { local $?; for ($apid, $wpid) { kill 'TERM', $_ if $_; waitpid $_, 0 if $_ } }

done_testing();
