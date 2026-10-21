use v5.10; use strict; use warnings;
use Test::More;
use Socket;
use File::Temp qw(tempdir);
use POSIX qw(WNOHANG _exit);
use Storable qw(nstore retrieve);
plan skip_all => 'integration test; set PROXY_IT=1 to run' unless $ENV{PROXY_IT};
require EV;
require Curl::Impersonate;
require Proxy::Impersonate;
require IO::Compress::Gzip;
require Scalar::Util;

my $tmp = tempdir(CLEANUP => 1);
my @children;
END {
    local $?;
    for my $pid (@children) {
        if (waitpid($pid, WNOHANG) == 0) { kill 'TERM', $pid; waitpid($pid, 0) }
    }
}

my $body = "decoded\0bytes\xff" x 4096;
my $encoded;
IO::Compress::Gzip::gzip(\$body => \$encoded) or die 'gzip failed';
socket(my $origin, PF_INET, SOCK_STREAM, 0) or die $!;
bind($origin, sockaddr_in(0, inet_aton('127.0.0.1'))) or die $!;
listen($origin, 8) or die $!;
my $port = (sockaddr_in(getsockname($origin)))[0];
my $opid = fork // die $!;
if (!$opid) {
    while (accept(my $s, $origin)) {
        my $req = '';
        while (index($req, "\r\n\r\n") < 0) { sysread($s, my $b, 4096) or last; $req .= $b }
        my ($path) = $req =~ m{^\S+ (/\S*)};
        my $response = $path eq '/gzip'
            ? "HTTP/1.1 200 OK\r\nContent-Encoding: gzip\r\nContent-Length: " . length($encoded) . "\r\n\r\n$encoded"
            : $path eq '/empty' ? "HTTP/1.1 204 No Content\r\n\r\n"
            : $path eq '/cached' ? "HTTP/1.1 304 Not Modified\r\nContent-Encoding: gzip\r\nContent-Length: 123\r\n\r\n"
            : $path eq '/head' ? "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\n"
            : "HTTP/1.1 200 OK\r\nContent-Length: " . length($req) . "\r\nConnection: close, x-private\r\nX-Private: secret\r\n\r\n$req";
        my $offset = 0;
        while ($offset < length $response) {
            my $n = syswrite($s, $response, length($response) - $offset, $offset) or last;
            $offset += $n;
        }
        close $s;
    }
    _exit(0);
}
push @children, $opid;
close $origin;

my ($weak, $shut_down, $serial);
my @connections;
my $timeout = $ENV{PROXY_TEST_TIMEOUT} // 3;
my $proxy = Proxy::Impersonate->new(impersonate => 'chrome131', cert_dir => "$tmp/proxy",
    on_request => sub { return { body => "snowman \x{2603}" } if $_[0]{url} =~ m{/local$}; return },
    on_response => sub {
        my ($c) = grep { $_->{inflight} } values %{$weak->{conns}};
        push @connections, ($c->{test_serial} //= ++$serial) if $c;
        if ($_[0]{url} =~ m{/shutdown$}) { $shut_down = 1; $weak->shutdown }
        return;
    });
$weak = $proxy; Scalar::Util::weaken($weak);
socket(my $idle, PF_INET, SOCK_STREAM, 0) or die $!;
connect($idle, sockaddr_in($proxy->port, inet_aton('127.0.0.1'))) or die $!;
$proxy->_accept;

my $cpid = fork // die $!;
if (!$cpid) {
    local $ENV{NO_PROXY} = ''; local $ENV{no_proxy} = '';
    my $client = Curl::Impersonate->new(timeout => $timeout, proxy => 'http://127.0.0.1:' . $proxy->port);
    my @results;
    for my $path (qw(gzip empty cached echo head local shutdown)) {
        push @results, $client->request(url => "http://127.0.0.1:$port/$path",
            method => $path eq 'head' ? 'HEAD' : 'GET',
            headers => { 'X-CSRF-Token' => 'token', Range => 'bytes=10-', 'If-None-Match' => '"tag"' });
    }
    nstore(\@results, "$tmp/results");
    _exit(0);
}
push @children, $cpid;
my $cw = EV::child($cpid, 0, sub { EV::break() });
my $timed_out;
my $tw = EV::timer($timeout * 7 + 3, 0, sub { $timed_out = 1; EV::break() });
EV::run();
ok(!$timed_out, 'streaming and callback teardown completed without hanging');
if (-f "$tmp/results") {
    my ($gzip, $empty, $cached, $echo, $head, $local, $shutdown) = @{ retrieve("$tmp/results") };
    is($gzip->{body}, $body, 'real compressed upstream is decoded byte for byte');
    ok(!exists $gzip->{headers}{'content-encoding'}, 'decoded response has no encoding header');
    is($empty->{status}, 204, '204 survives on the same client connection');
    is($empty->{body}, '', '204 has no body');
    is($cached->{status}, 304, '304 survives on the same client connection');
    ok(!exists $cached->{headers}{'content-length'} && !exists $cached->{headers}{'content-encoding'},
       '304 cannot relabel cached decoded content with encoded metadata');
    like($echo->{body}, qr/x-csrf-token: token/i, 'application header reaches a real origin');
    like($echo->{body}, qr/range: bytes=10-/i, 'range header reaches a real origin');
    like($echo->{body}, qr/accept-encoding: identity/i, 'ranges request uncompressed bytes from the origin');
    like($echo->{body}, qr/if-none-match: "tag"/i, 'cache validator reaches a real origin');
    ok(!exists $echo->{headers}{'x-private'}, 'connection-nominated response header is removed');
    is($head->{status}, 200, 'HEAD with a nonzero representation length succeeds through the proxy');
    is($head->{body}, '', 'HEAD forwards no body');
    is($head->{headers}{'content-length'}, 5, 'unencoded HEAD retains its representation length');
    is($local->{body}, "snowman \xe2\x98\x83", 'synthetic UTF-8 response works on a reused connection');
    ok($shutdown->{error}, 'shutdown from a real response callback disconnects the client');
}
else { fail('client produced results') }
EV::run(EV::RUN_NOWAIT());
ok($shut_down && !$proxy->{multi} && !keys %{$proxy->{conns}}, 'callback shutdown releases active and idle connections');
is_deeply(\@connections, [1, 1, 1, 1, 1, 1], 'decoded and bodyless responses reuse one client connection');
$proxy->shutdown;

done_testing;
