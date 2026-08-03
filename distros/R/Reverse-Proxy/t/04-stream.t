use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Reverse::Proxy;

# Backend that replies with a chunked body in several pieces (no Content-Length),
# so streaming mode must forward it chunk-by-chunk.
sub spawn_backend {
	my $srv = IO::Socket::INET->new(
		LocalHost => '127.0.0.1', LocalPort => 0, Listen => 8, ReuseAddr => 1,
	) or die "listen: $!";
	my $port = $srv->sockport;
	my $pid  = fork // die "fork: $!";
	if (!$pid) {
		while (my $c = $srv->accept) {
			$c->autoflush(1);
			while (my $l = <$c>) { last if $l eq "\r\n" }
			print $c "HTTP/1.1 200 OK\r\n"
				. "Content-Type: text/plain\r\n"
				. "Transfer-Encoding: chunked\r\n"   # hop-by-hop; must be stripped
				. "Connection: close\r\n\r\n";
			for my $p ('hello', ' ', 'world') {
				printf $c "%x\r\n%s\r\n", length($p), $p;
			}
			print $c "0\r\n\r\n";
			close $c;
			last;
		}
		exit 0;
	}
	return ($pid, $port);
}

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

# A minimal PSGI streaming responder that records everything.
{
	package MockWriter;
	sub new   { bless { writes => [], closed => 0 }, shift }
	sub write { push @{ $_[0]{writes} }, $_[1] }
	sub close { $_[0]{closed} = 1 }
}

my ($pid, $port) = spawn_backend();
select undef, undef, undef, 0.2;

my $app = Reverse::Proxy->new(
	upstream => "http://127.0.0.1:$port", stream => 1,
)->to_app;

my $res = $app->(make_env('/stream'));
is(ref($res), 'CODE', 'streaming mode returns a psgi.streaming coderef');

my ($status, $headers, $writer);
$res->(sub { ($status, $headers) = @{ $_[0] }; $writer = MockWriter->new; return $writer });

is($status, 200, 'streamed status is 200');
is(join('', @{ $writer->{writes} }), 'hello world', 'streamed body reassembles correctly');
ok(@{ $writer->{writes} } >= 1, 'body delivered via writer->write');
ok($writer->{closed}, 'writer closed at end of stream');

# hop-by-hop Transfer-Encoding must not leak into the streamed response headers
my %h; for (my $i = 0; $i + 1 < @$headers; $i += 2) { $h{ lc $headers->[$i] } = $headers->[$i+1] }
is($h{'transfer-encoding'}, undef, 'Transfer-Encoding stripped from streamed headers');
is($h{'content-type'}, 'text/plain', 'Content-Type preserved in streamed headers');

END { if ($pid) { local $?; kill 'TERM', $pid; waitpid $pid, 0 } }

done_testing();
