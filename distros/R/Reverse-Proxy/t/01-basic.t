use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Reverse::Proxy;

# A tiny HTTP/1.1 backend that echoes what it received, and replies with a
# hop-by-hop header (Keep-Alive) plus two Set-Cookie headers so we can check
# stripping and multi-value preservation.
sub spawn_backend {
	my $srv = IO::Socket::INET->new(
		LocalHost => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1,
	) or die "listen: $!";
	my $port = $srv->sockport;
	my $pid  = fork // die "fork: $!";
	if (!$pid) {
		while (my $c = $srv->accept) {
			$c->autoflush(1);
			my $line = <$c>; $line = '' unless defined $line;
			$line =~ s/\r\n$//;
			my ($method, $uri) = split /\s+/, $line;
			my %hdr;
			while (my $h = <$c>) { $h =~ s/\r\n$//; last if $h eq '';
				my ($k, $v) = split /:\s*/, $h, 2; $hdr{ lc $k } = $v; }
			my $body = '';
			if (my $len = $hdr{'content-length'}) { read($c, $body, $len) }
			my $out = join ' ',
				"M=$method", "U=$uri",
				"XFF=" . ($hdr{'x-forwarded-for'}  // ''),
				"XFP=" . ($hdr{'x-forwarded-proto'}// ''),
				"XC="  . ($hdr{'x-custom'}          // ''),
				"HOST=". ($hdr{'host'}             // ''),
				"BODY=$body";
			print $c "HTTP/1.1 200 OK\r\n"
				. "Content-Type: text/plain\r\n"
				. "Keep-Alive: timeout=5\r\n"      # hop-by-hop -> must be stripped
				. "Set-Cookie: a=1\r\n"
				. "Set-Cookie: b=2\r\n"
				. "Content-Length: " . length($out) . "\r\n"
				. "Connection: close\r\n\r\n"
				. $out;
			close $c;
		}
		exit 0;
	}
	return ($pid, $port);
}

sub make_env {
	my ($method, $path, $qs, $hdrs, $body) = @_;
	open my $in, '<', \(my $b = defined $body ? $body : '');
	my %env = (
		REQUEST_METHOD  => $method,
		PATH_INFO       => $path,
		QUERY_STRING    => defined $qs ? $qs : '',
		SERVER_PROTOCOL => 'HTTP/1.1',
		REMOTE_ADDR     => '203.0.113.7',
		'psgi.version'  => [1, 1],
		'psgi.url_scheme' => 'http',
		'psgi.input'    => $in,
		'psgi.errors'   => \*STDERR,
	);
	$env{CONTENT_LENGTH} = length $body if defined $body;
	for my $k (keys %{ $hdrs || {} }) {
		(my $n = uc $k) =~ tr/-/_/;
		$env{"HTTP_$n"} = $hdrs->{$k};
	}
	return \%env;
}

sub header_val {   # first value for a name in a PSGI header arrayref
	my ($h, $name) = @_;
	for (my $i = 0; $i + 1 < @$h; $i += 2) {
		return $h->[$i + 1] if lc $h->[$i] eq lc $name;
	}
	return undef;
}
sub header_all {
	my ($h, $name) = @_;
	my @v;
	for (my $i = 0; $i + 1 < @$h; $i += 2) {
		push @v, $h->[$i + 1] if lc $h->[$i] eq lc $name;
	}
	return @v;
}

my ($pid, $port) = spawn_backend();
select undef, undef, undef, 0.2;

my $app = Reverse::Proxy->new(upstream => "http://127.0.0.1:$port")->to_app;

# ---- GET with query + a custom header ------------------------------------
{
	my $res = $app->(make_env(GET => '/foo/bar', 'baz=1', { 'X-Custom' => 'hi' }));
	is($res->[0], 200, 'GET proxied, 200');
	my $body = $res->[2][0];
	like($body, qr/\bM=GET\b/,            'method forwarded');
	like($body, qr{\bU=/foo/bar\?baz=1\b}, 'path + query forwarded');
	like($body, qr/\bXC=hi\b/,            'custom request header forwarded');
	like($body, qr/\bXFF=203\.0\.113\.7\b/, 'X-Forwarded-For added from REMOTE_ADDR');
	like($body, qr/\bXFP=http\b/,         'X-Forwarded-Proto added');
	like($body, qr/\bHOST=127\.0\.0\.1:$port\b/, 'Host set from upstream (no preserve_host)');

	is(header_val($res->[1], 'Content-Type'), 'text/plain', 'response Content-Type passed through');
	is(header_val($res->[1], 'Keep-Alive'), undef, 'hop-by-hop Keep-Alive stripped from response');
	is(header_val($res->[1], 'Connection'), undef, 'hop-by-hop Connection stripped from response');
	is_deeply([ header_all($res->[1], 'Set-Cookie') ], [ 'a=1', 'b=2' ],
		'multi-value Set-Cookie preserved in order');
}

# ---- POST with a body -----------------------------------------------------
{
	my $res = $app->(make_env(POST => '/submit', '', {}, 'hello=world'));
	is($res->[0], 200, 'POST proxied, 200');
	like($res->[2][0], qr/\bM=POST\b/,           'POST method forwarded');
	like($res->[2][0], qr/\bBODY=hello=world\b/, 'request body forwarded');
}

# ---- preserve_host --------------------------------------------------------
{
	my $keep = Reverse::Proxy->new(
		upstream => "http://127.0.0.1:$port", preserve_host => 1,
	)->to_app;
	my $res = $keep->(make_env(GET => '/', '', { Host => 'client.example' }));
	like($res->[2][0], qr/\bHOST=client\.example\b/, 'preserve_host forwards client Host');
}

END { if ($pid) { local $?; kill 'TERM', $pid; waitpid $pid, 0 } }

done_testing();
