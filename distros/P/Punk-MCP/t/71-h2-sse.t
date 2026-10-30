#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    plan skip_all => 'live Hyperman tests need RELEASE_TESTING or PMCP_LIVE'
        unless $ENV{RELEASE_TESTING} || $ENV{PMCP_LIVE};
    plan skip_all => 'Hyperman is not installed' unless eval { require Hyperman; 1 };
    plan skip_all => 'Hyperman is built without TLS or nghttp2'
        unless Hyperman->has_tls && Hyperman->has_http2;
    plan skip_all => 'no openssl CLI' unless `openssl version 2>/dev/null`;
}

use File::Temp ();
use JSON::PP ();
use Time::HiRes ();
use PMCPSpawn;
use PMCPLiveApp;

my $V = '2025-11-25';
my $dir = File::Temp::tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" -out "$cert" }
     . qq{-days 1 -subj "/CN=localhost" >/dev/null 2>&1}) == 0 or BAIL_OUT('openssl req failed');

# Homebrew's curl and the system's: they differ in TLS library and nghttp2.
my @CURLS = grep { -x $_ && `$_ --version 2>/dev/null` =~ /\bHTTP2\b/ }
            '/opt/homebrew/opt/curl/bin/curl', '/usr/bin/curl';
plan skip_all => 'no curl with HTTP/2' unless @CURLS;

my $h = spawn_app(live_source(), workers => 2,
                  run => "tls_cert => '$cert', tls_key => '$key', http2 => 1");
my $URL = "https://127.0.0.1:$h->{port}/mcp";

# curl over h2. Returns (exit code, headers, body).
sub curl {
    my ($curl, $method, $headers, $body, @more) = @_;
    my $hfile = "$dir/h.$$." . int(rand 1e9);
    my @cmd = ($curl, '-sk', '--http2', '-X', $method, '-D', $hfile, '-o', '-',
               (map { ('-H', "$_: $headers->{$_}") } sort keys %$headers),
               (defined $body ? ('-H', 'Content-Type: application/json', '--data-binary', $body) : ()),
               @more, $URL);
    open my $fh, '-|', @cmd or die "$curl: $!";
    my $out = do { local $/; <$fh> } // '';
    close $fh;
    my $code = $? >> 8;
    my $hd = do { local $/; open my $f, '<', $hfile or return ($code, '', $out); <$f> };
    unlink $hfile;
    return ($code, $hd, $out);
}

for my $curl (@CURLS) {
    note("---- $curl");
    my ($code, $hd, $out) = curl($curl, 'POST', { Accept => 'application/json, text/event-stream' },
        mcp_body(1, 'initialize', { protocolVersion => $V, capabilities => {},
                                    clientInfo => { name => 't71', version => '1' } }));
    like($hd, qr{^HTTP/2 200}m, "$curl: initialize over h2");
    my ($sid) = $hd =~ /^mcp-session-id:\s*(\S+)/mi;
    ok($sid, 'with a session id');
    my %S = (Accept => 'application/json, text/event-stream', 'Mcp-Session-Id' => $sid);

    ($code, $hd, $out) = curl($curl, 'POST', \%S,
        mcp_body(2, 'tools/call', { name => 'slow', arguments => {}, _meta => { progressToken => 'p' } }),
        '-N', '--max-time', '10');
    is($code, 0, 'a streamed call ends cleanly');
    like($hd, qr{^content-type:\s*text/event-stream}mi, 'as a stream');
    like($out, qr/notifications\/progress.*slow done \d+/s, 'progress, then the answer');
    like($out, qr/^: ping/m, 'with a heartbeat between');

    ($code, undef, $out) = curl($curl, 'POST', \%S, mcp_body(3, 'resources/subscribe', { uri => 'books://1' }));
    like($out, qr/"result"/, 'subscribe');

    # The server stream in a child curl, written to a file as it arrives.
    my $sfile = "$dir/stream.$$";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        open STDOUT, '>', $sfile or POSIX::_exit(1);
        open STDERR, '>', '/dev/null';
        exec $curl, '-sk', '--http2', '-N', '--max-time', '15', '-H', 'Accept: text/event-stream',
             '-H', "Mcp-Session-Id: $sid", $URL or POSIX::_exit(1);
    }
    my $seen = sub {
        my ($re, $secs) = @_;
        my $end = Time::HiRes::time() + $secs;
        while (Time::HiRes::time() < $end) {
            if (open my $f, '<', $sfile) {
                my $got = do { local $/; <$f> } // '';
                return 1 if $got =~ $re;
            }
            Time::HiRes::sleep(0.05);
        }
        return 0;
    };
    ok($seen->(qr/: worker \d+/, 5), 'GET opens the server stream over h2');

    curl($curl, 'POST', \%S, mcp_body(4, 'tools/call', { name => 'touch', arguments => {} }));
    ok($seen->(qr/resources\/updated.*books:\/\/1/s, 5), 'a resource update arrives on it');

    my $t0 = Time::HiRes::time();
    ($code, $hd) = curl($curl, 'DELETE', { 'Mcp-Session-Id' => $sid });
    like($hd, qr{^HTTP/2 204}m, 'DELETE');
    waitpid $pid, 0;
    my $exit = $? >> 8;
    is($exit, 0, 'ends the h2 stream cleanly, not by curl\'s timeout');
    cmp_ok(Time::HiRes::time() - $t0, '<', 10, 'and promptly');
    unlink $sfile;
}

my $log = stop_app($h);
unlike($log, qr/\b(?:panic|Segmentation|uncaught)\b/i, 'the server logged no crash') or diag $log;

done_testing;
