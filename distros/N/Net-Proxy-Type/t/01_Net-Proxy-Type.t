use strict;
use IO::Socket::INET qw(:DEFAULT :crlf);
use Test::More;
BEGIN { 
	if( $^O eq 'MSWin32' ) {
		plan skip_all => 'Windows implementation of fork() is broken';
	}
	else {
		plan tests => 13;
	}
	use_ok('Net::Proxy::Type') 
};

my $pt = Net::Proxy::Type->new();
ok(defined($pt), "new()");
isa_ok($pt, "Net::Proxy::Type");

my $sock = IO::Socket::INET->new(Listen => 3)
	or die $@;
my ($host, $port) = ($sock->sockhost eq "0.0.0.0" ? "127.0.0.1" : $sock->sockhost, $sock->sockport);
$sock->close();
is($pt->get($host, $port), Net::Proxy::Type::DEAD_PROXY, "DEAD_PROXY test");
my ($type, $conn_time) = $pt->get($host, $port);
is($type, Net::Proxy::Type::DEAD_PROXY, "DEAD_PROXY in list context test");
is($conn_time, 0, "DEAD_PROXY conn time");

my $pid;
($pid, $host, $port) = make_fake_http_proxy();
is($pt->is_http($host, $port), 1, 'HTTP_PROXY');
is($pt->is_https($host, $port), 0, 'Not HTTPS_PROXY');
$pt->strict(1);
is($pt->get($host, $port), Net::Proxy::Type::HTTP_PROXY, 'get for HTTP_PROXY');
kill 15, $pid;

($pid, $host, $port) = make_fake_https_proxy(0);
$pt->https_strict(0);
$pt->timeout(3);
is($pt->get($host, $port), Net::Proxy::Type::HTTPS_PROXY, 'non strict get for HTTPS_PROXY');
diag "next test will take about 10 sec";
$pt->strict(1);
is($pt->get($host, $port), Net::Proxy::Type::UNKNOWN_PROXY, 'strict get for HTTPS_PROXY');
$pt->strict(0);
ok(!$pt->is_connect($host, $port), 'is_connect for HTTPS_PROXY');
kill 15, $pid;

($pid, $host, $port) = make_fake_https_proxy(1);
$pt->strict(0);
is($pt->get($host, $port), Net::Proxy::Type::CONNECT_PROXY, 'get for CONNECT_PROXY');
kill 15, $pid;

sub make_fake_http_proxy {
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
	
	my $child = fork;
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			my $client = $serv->accept()
				or next;
			
			my $headers;
			my $no_headers_end;
			my $rc;
			do {
				$rc = $client->sysread($headers, 1024, length $headers);
				
			} while ($no_headers_end = index($headers, CRLF.CRLF) == -1 and $rc);
			
			next if $no_headers_end;
			my ($url) = $headers =~ m!^GET (\S+) HTTP/\d.\d! or next;
			$client->syswrite('HTTP/1.1 200 OK' . CRLF . 'Cookie: google' . CRLF . CRLF);
		}
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}

sub make_fake_https_proxy {
	my $allow_not_443 = shift;
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
	
	my $child = fork;
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			my $client = $serv->accept()
				or next;
			
			my $headers;
			my $no_headers_end;
			my $rc;
			do {
				$rc = $client->sysread($headers, 1024, length $headers);
				
			} while ($no_headers_end = index($headers, CRLF.CRLF) == -1 and $rc);
			
			next if $no_headers_end;
			my ($url) = $headers =~ m!^CONNECT (\S+) HTTP/\d.\d! or next;
			if (!$allow_not_443 && index($url, ':443') == -1) {
				$client->syswrite('HTTP/1.1 403 FORBIDDEN' . CRLF . CRLF);
			}
			else {
				$client->syswrite('HTTP/1.1 200 OK' . CRLF . CRLF);
			}
		}
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}
