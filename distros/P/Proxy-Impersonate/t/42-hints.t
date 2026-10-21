use v5.10; use strict; use warnings;
use Test::More;
use Socket;
use File::Temp qw(tempdir);
plan skip_all => 'integration test; set PROXY_IT=1 to run' unless $ENV{PROXY_IT};
require EV;
require Proxy::Impersonate;

# a local plain-HTTP origin that echoes the request head and always sends
# Accept-CH for a high-entropy hint.
socket(my $osrv, PF_INET, SOCK_STREAM, 0) or die $!;
setsockopt($osrv, SOL_SOCKET, SO_REUSEADDR, 1);
bind($osrv, sockaddr_in(0, inet_aton('127.0.0.1'))) or die $!;
listen($osrv, 5) or die $!;
my $oport = (sockaddr_in(getsockname($osrv)))[0];
my $opid = fork // die $!;
if (!$opid) {
    for (1..6) {
        accept(my $c, $osrv) or last;
        my $req = ''; while (index($req, "\r\n\r\n") < 0) { sysread($c, my $b, 4096) or last; $req .= $b }
        syswrite($c, "HTTP/1.1 200 OK\r\nAccept-CH: sec-ch-ua-platform-version\r\n"
            . "Content-Type: text/plain\r\nContent-Length: " . length($req) . "\r\nConnection: close\r\n\r\n$req");
        close $c;
    }
    exit 0;
}
close $osrv;

my $proxy = Proxy::Impersonate->new(impersonate => 'chrome131', listen => '127.0.0.1:0',
    cert_dir => tempdir(CLEANUP => 1), verify => 0,
    override_headers     => { 'user-agent' => 'X', 'sec-ch-ua-platform' => '"Windows"' },
    high_entropy_headers => { 'sec-ch-ua-platform-version' => '"10.0.0"' });

# two sequential plain-HTTP requests through the proxy to the same origin
sub fetch {
    my $result = tempdir(CLEANUP => 1) . '/r';
    my $pid = fork // die $!;
    if (!$pid) {
        socket(my $s, PF_INET, SOCK_STREAM, 0);
        setsockopt($s, SOL_SOCKET, SO_RCVTIMEO, pack('l!l!', 15, 0));
        connect($s, sockaddr_in($proxy->port, inet_aton('127.0.0.1')));
        syswrite($s, "GET http://127.0.0.1:$oport/ HTTP/1.1\r\nHost: 127.0.0.1:$oport\r\nAccept: */*\r\nConnection: close\r\n\r\n");
        my $buf = ''; while (1) { my $n = sysread($s, my $b, 8192); last if !$n; $buf .= $b } _save($result, $buf); exit 0;
    }
    my $cw = EV::child($pid, 0, sub { EV::break() });
    my $tw = EV::timer(20, 0, sub { EV::break() });
    EV::run(); waitpid($pid, 0);
    return do { local $/; open my $f, '<', $result or return ''; <$f> };
}

my $first  = fetch();   # host not yet seen -> no high-entropy hint
my $second = fetch();   # after Accept-CH -> the hint is added
kill 'TERM', $opid; waitpid($opid, 0);

# the origin echoes the request it received in the RESPONSE BODY; check that (the
# response headers themselves carry Accept-CH, which would false-match otherwise)
sub req { my ($resp) = @_; my ($b) = ($resp // '') =~ /\r\n\r\n(.*)/s; return $b // '' }
my ($r1, $r2) = (req($first), req($second));

unlike($r1, qr/sec-ch-ua-platform-version/i, 'no high-entropy hint before Accept-CH');
like($r2, qr/sec-ch-ua-platform-version: "10\.0\.0"/i,
     'high-entropy hint added on the next request after the host sent Accept-CH');
like($r2, qr/sec-ch-ua-platform: "Windows"/i, 'low-entropy hint always present');
done_testing;

sub _save { my ($p, $d) = @_; open my $f, '>', $p or die; print $f $d; close $f }
