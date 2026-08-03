use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Reverse::Proxy;

# Request-side header handling: hop-by-hop stripping (including names listed in
# the client's own Connection header), X-Forwarded-For chaining, X-Forwarded-Host,
# a pre-existing X-Forwarded-Proto, and the Via header (default and omitted).
#
# The backend echoes every request header it received back in the body, one
# "name: value" per line, so the test can assert exactly what was forwarded.

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
			my @hdrs;
			while (my $h = <$c>) { $h =~ s/\r\n$//; last if $h eq ''; push @hdrs, $h }
			my $out = join "\n", @hdrs;
			print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
				. "Content-Length: " . length($out) . "\r\nConnection: close\r\n\r\n$out";
			close $c;
		}
		exit 0;
	}
	return ($pid, $port);
}

sub make_env {
	my ($hdrs) = @_;
	open my $in, '<', \(my $b = '');
	my %env = (
		REQUEST_METHOD => 'GET', PATH_INFO => '/', QUERY_STRING => '',
		SERVER_PROTOCOL => 'HTTP/1.1', REMOTE_ADDR => '203.0.113.7',
		'psgi.version' => [1,1], 'psgi.url_scheme' => 'http',
		'psgi.input' => $in, 'psgi.errors' => \*STDERR,
	);
	for my $k (keys %{ $hdrs || {} }) {
		(my $n = uc $k) =~ tr/-/_/;
		$env{"HTTP_$n"} = $hdrs->{$k};
	}
	return \%env;
}

# Parse the echoed header block into a lowercased name => value map.
sub seen_headers {
	my ($body) = @_;
	my %h;
	for my $line (split /\n/, $body) {
		next unless $line =~ /^([^:]+):\s*(.*)$/;
		$h{ lc $1 } = $2;
	}
	return \%h;
}

my ($pid, $port) = spawn_backend();
select undef, undef, undef, 0.2;

my $app = Reverse::Proxy->new(upstream => "http://127.0.0.1:$port")->to_app;

# ---- hop-by-hop stripping (fixed set + Connection-named tokens) -----------
{
	my $res = $app->(make_env({
		'Connection'        => 'close, X-Custom-Hop',   # names X-Custom-Hop as hop
		'X-Custom-Hop'      => 'secret',                # must be dropped
		'Upgrade'           => 'h2c',                   # hop-by-hop
		'TE'                => 'trailers',              # hop-by-hop
		'X-Keep'            => 'yes',                   # ordinary -> forwarded
	}));
	is($res->[0], 200, 'request with hop-by-hop headers proxied 200');
	my $h = seen_headers($res->[2][0]);
	is($h->{'connection'},   undef, 'Connection stripped from forwarded request');
	is($h->{'x-custom-hop'}, undef, 'header named in client Connection is stripped');
	is($h->{'upgrade'},      undef, 'Upgrade stripped from forwarded request');
	is($h->{'te'},           undef, 'TE stripped from forwarded request');
	is($h->{'x-keep'},       'yes', 'ordinary header forwarded through');
}

# ---- X-Forwarded-For chaining --------------------------------------------
{
	my $res = $app->(make_env({ 'X-Forwarded-For' => '10.0.0.1' }));
	my $h = seen_headers($res->[2][0]);
	is($h->{'x-forwarded-for'}, '10.0.0.1, 203.0.113.7',
		'existing X-Forwarded-For chained with REMOTE_ADDR');
}

# ---- X-Forwarded-Host from client Host -----------------------------------
{
	my $res = $app->(make_env({ Host => 'client.example' }));
	my $h = seen_headers($res->[2][0]);
	is($h->{'x-forwarded-host'}, 'client.example',
		'X-Forwarded-Host derived from client Host');
}

# ---- pre-existing X-Forwarded-Proto preserved ----------------------------
{
	my $res = $app->(make_env({ 'X-Forwarded-Proto' => 'https' }));
	my $h = seen_headers($res->[2][0]);
	is($h->{'x-forwarded-proto'}, 'https',
		'existing X-Forwarded-Proto preserved (not overwritten by url_scheme)');
}

# ---- Via header: default value -------------------------------------------
{
	my $res = $app->(make_env({}));
	my $h = seen_headers($res->[2][0]);
	is($h->{'via'}, 'Reverse::Proxy', 'default Via header added');
}

# ---- Via header: omitted when via => undef -------------------------------
{
	my $novia = Reverse::Proxy->new(
		upstream => "http://127.0.0.1:$port", via => undef,
	)->to_app;
	my $res = $novia->(make_env({}));
	my $h = seen_headers($res->[2][0]);
	is($h->{'via'}, undef, 'via => undef omits the Via header');
}

END { if ($pid) { local $?; kill 'TERM', $pid; waitpid $pid, 0 } }

done_testing();
