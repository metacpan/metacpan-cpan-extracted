use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Reverse::Proxy;

# The third target mode: resolver => sub { $env -> base url | undef }. Two
# labelled backends; the resolver picks one by Host, or returns undef (-> 404).

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
	my ($path, $host) = @_;
	open my $in, '<', \(my $b = '');
	return {
		REQUEST_METHOD => 'GET', PATH_INFO => $path, QUERY_STRING => '',
		SERVER_PROTOCOL => 'HTTP/1.1', REMOTE_ADDR => '127.0.0.1',
		(defined $host ? (HTTP_HOST => $host) : ()),
		'psgi.version' => [1,1], 'psgi.url_scheme' => 'http',
		'psgi.input' => $in, 'psgi.errors' => \*STDERR,
	};
}

my ($apid, $aport) = spawn_backend('admin');
my ($ppid, $pport) = spawn_backend('public');
select undef, undef, undef, 0.2;

my $calls = 0;
my $app = Reverse::Proxy->new(
	resolver => sub {
		my $env = shift;
		$calls++;
		return undef if ($env->{PATH_INFO} // '') eq '/blocked';
		return $env->{HTTP_HOST} && $env->{HTTP_HOST} =~ /^admin\./
			? "http://127.0.0.1:$aport"
			: "http://127.0.0.1:$pport";
	},
)->to_app;

# admin.* -> admin backend
{
	my $res = $app->(make_env('/x', 'admin.example'));
	is($res->[0], 200, 'resolver: admin host proxied 200');
	like($res->[2][0], qr/\bTAG=admin\b/, 'resolver chose the admin upstream');
	like($res->[2][0], qr{\bU=/x\b},      'resolver forwards PATH_INFO unchanged');
}

# anything else -> public backend
{
	my $res = $app->(make_env('/y', 'www.example'));
	is($res->[0], 200, 'resolver: non-admin host proxied 200');
	like($res->[2][0], qr/\bTAG=public\b/, 'resolver fell through to the public upstream');
}

# resolver returns undef -> 404
{
	my $res = $app->(make_env('/blocked', 'admin.example'));
	is($res->[0], 404, 'resolver returning undef gives 404');
	like($res->[2][0], qr{No upstream for /blocked}, '404 body names the path');
}

ok($calls >= 3, 'resolver coderef was invoked once per request');

END { local $?; for ($apid, $ppid) { kill 'TERM', $_ if $_; waitpid $_, 0 if $_ } }

done_testing();
