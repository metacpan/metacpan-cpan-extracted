use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Reverse::Proxy;

# The request target is spliced into the upstream request line, and PATH_INFO
# reaches a PSGI app percent-DECODED. So a client URL of "/x%0d%0a..." arrives
# here as a real CRLF, and forwarding it verbatim would end the request line
# and start a second request on the upstream connection: request smuggling
# past whatever the proxy in front is enforcing.
#
# The backend echoes the raw bytes it read back in the body, so the test can
# assert on the request line the upstream actually saw - and, crucially, that
# it saw exactly ONE request.

sub spawn_backend {
	my $srv = IO::Socket::INET->new(
		LocalHost => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1,
	) or die "listen: $!";
	my $port = $srv->sockport;
	my $pid  = fork // die "fork: $!";
	if (!$pid) {
		while (my $c = $srv->accept) {
			$c->autoflush(1);
			my $buf = '';
			while (sysread($c, my $chunk, 4096)) {
				$buf .= $chunk;
				last if $buf =~ /\r\n\r\n/;
			}
			print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
				. "Content-Length: " . length($buf) . "\r\nConnection: close\r\n\r\n$buf";
			close $c;
		}
		exit 0;
	}
	return ($pid, $port);
}

sub make_env {
	my ($path, $query) = @_;
	open my $in, '<', \(my $b = '');
	return {
		REQUEST_METHOD => 'GET', PATH_INFO => $path,
		QUERY_STRING => defined $query ? $query : '',
		SERVER_PROTOCOL => 'HTTP/1.1', REMOTE_ADDR => '203.0.113.7',
		'psgi.version' => [1,1], 'psgi.url_scheme' => 'http',
		'psgi.input' => $in, 'psgi.errors' => \*STDERR,
	};
}

my ($pid, $port) = spawn_backend();
select undef, undef, undef, 0.2;

my $app = Reverse::Proxy->new(upstream => "http://127.0.0.1:$port")->to_app;

# ---- CRLF in a decoded path cannot open a second request -----------------
{
	my $smuggled = "/x\r\nX-Smuggled: yes\r\n\r\nGET /admin HTTP/1.1\r\nHost: internal\r\n\r\n";
	my $res = $app->(make_env($smuggled));
	is($res->[0], 200, 'request with CRLF in PATH_INFO still proxies');

	my $seen = $res->[2][0];
	my ($line) = split /\r\n/, $seen, 2;
	like($line, qr{^GET /x%0D%0A}, 'decoded CRLF is re-encoded into the target');
	unlike($seen, qr{^X-Smuggled:}m, 'no injected header reached the upstream');
	is(scalar(() = $seen =~ /HTTP\/1\.1\r\n/g), 1, 'upstream saw exactly one request line');
	unlike($seen, qr{GET /admin}, 'the smuggled request is not a request');
}

# ---- the other target-terminating bytes ----------------------------------
{
	my %case = (
		"/a b"      => qr{^GET /a%20b },     # decoded space would split the line
		"/a?b"      => qr{^GET /a%3Fb},      # decoded '?' would start the query
		"/a#b"      => qr{^GET /a%23b},      # decoded '#' would truncate
		"/a%b"      => qr{^GET /a%25b},      # a literal '%' came from %25
		"/a\x7fb"   => qr{^GET /a%7Fb},      # DEL
	);
	for my $path (sort keys %case) {
		my $res = $app->(make_env($path));
		my ($line) = split /\r\n/, $res->[2][0], 2;
		(my $shown = $path) =~ s/([^\x20-\x7e])/sprintf "\\x%02x", ord $1/ge;
		like($line, $case{$path}, "'$shown' is encoded in the request line");
	}
}

# ---- ordinary paths are untouched ----------------------------------------
{
	for my $path ('/', '/a/b/c', '/a-b_c.d~e', '/x:y@z', '/a+b', '/(a)') {
		my $res = $app->(make_env($path));
		my ($line) = split /\r\n/, $res->[2][0], 2;
		is($line, "GET $path HTTP/1.1", "'$path' forwarded unchanged");
	}
	my $res = $app->(make_env('/s', 'a=1&b=%20c'));
	my ($line) = split /\r\n/, $res->[2][0], 2;
	is($line, 'GET /s?a=1&b=%20c HTTP/1.1', 'undecoded query forwarded byte for byte');
}

# ---- a query string cannot terminate the line either ---------------------
{
	my $res = $app->(make_env('/s', "a=1\r\nX-Smuggled: yes"));
	my $seen = $res->[2][0];
	unlike($seen, qr{^X-Smuggled:}m, 'CRLF in QUERY_STRING injects nothing');
	is(scalar(() = $seen =~ /HTTP\/1\.1\r\n/g), 1, 'still exactly one request line');
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing();
