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
}

use JSON::PP ();
use Time::HiRes ();
use PMCPSpawn;
use PMCPLiveApp;

my $JSON = JSON::PP->new->canonical;
my $V = '2025-11-25';

# A POST on a kept-alive socket. Returns (status, headers, decoded body or raw).
sub post {
    my ($sock, $sid, $id, $method, $params, $accept) = @_;
    my ($st, $hd, $b) = request($sock, 'POST', '/mcp',
        { Accept => $accept // 'application/json',
          ($sid ? ('Mcp-Session-Id' => $sid) : ()) },
        mcp_body($id, $method, $params));
    my $msg = eval { $JSON->decode($b) } // $b;
    return ($st, $hd, $msg);
}

sub text_of { my ($m) = @_; ref $m eq 'HASH' ? $m->{result}{content}[0]{text} // '' : '' }

sub initialize {
    my ($h) = @_;
    my $s = conn($h);
    my ($st, $hd, $m) = post($s, undef, 1, 'initialize', { protocolVersion => $V,
        capabilities => {}, clientInfo => { name => 't70', version => '1' } });
    my $sid = $hd->{"mcp-session-id"};
    return ($st, $sid, $hd, $sid ? worker_of($s, $sid) : undef);
}

# The worker a kept-alive socket is on.
sub worker_of {
    my ($sock, $sid) = @_;
    my (undef, undef, $m) = post($sock, $sid, 90, 'tools/call', { name => 'pid', arguments => {} });
    return text_of($m);
}

# Keep a socket's worker busy for 1.5s, and read the answer later.
sub hold_send {
    my ($s, $sid) = @_;
    my $b = mcp_body(91, "tools/call", { name => "hold", arguments => {} });
    print {$s} "POST /mcp HTTP/1.1\r\nHost: localhost\r\nAccept: application/json\r\n"
        . "Content-Type: application/json\r\nMcp-Session-Id: $sid\r\n"
        . "Content-Length: " . length($b) . "\r\n\r\n$b";
}

sub hold_read {
    my ($s) = @_;
    local $/ = "\r\n";
    my $len = 0;
    while (defined(my $l = <$s>)) {
        last if $l eq "\r\n";
        $len = $1 if $l =~ /^Content-Length:\s*(\d+)/i;
    }
    read $s, my $skip, $len;
}

# One kept-alive socket per worker: { pid => socket }. An idle worker takes
# most connections (macOS balances none, even with SO_REUSEPORT), so each
# worker found is kept busy by the hold tool while the next connection is made,
# and the holds are read back once every worker has a socket.
sub every_worker {
    my ($h, $sid, $n) = @_;
    my (%on, @held);
    for (1 .. 3 * $n) {
        last if keys %on == $n;
        my $s = conn($h);
        my $w = worker_of($s, $sid);
        next if $w !~ /^\d+$/ || $on{$w};
        $on{$w} = $s;
        hold_send($s, $sid);
        push @held, $s;
        Time::HiRes::sleep(0.1);
    }
    hold_read($_) for @held;
    return \%on;
}

my $h = spawn_app(live_source(), workers => 3);

# ---- a session spans the pool ---------------------------------------------------

my ($st, $sid, undef, $iwid) = initialize($h);
is($st, 200, 'initialize');
ok($sid, 'with a session id');

my $ON = every_worker($h, $sid, 3);
is(scalar(keys %$ON), 3, "the session answers on all three workers: " . join(" ", sort keys %$ON));

# ---- resources/updated from another worker -----------------------------------

hold_send($ON->{$iwid}, $sid);
Time::HiRes::sleep(0.1);
my ($gs, $gst) = stream_open($h, '/mcp', { Accept => 'text/event-stream', 'Mcp-Session-Id' => $sid });
is($gst, 200, 'GET opens the server stream');
my ($gbuf, $ok) = stream_wait($gs, qr/: worker (\d+)/, 5);
my ($spid) = $gbuf =~ /: worker (\d+)/;
hold_read($ON->{$iwid});
ok($spid, "the stream is held by worker $spid");

my (undef, $quiet) = initialize($h);
my ($qs) = stream_open($h, '/mcp', { Accept => 'text/event-stream', 'Mcp-Session-Id' => $quiet });
my ($qbuf) = stream_wait($qs, qr/: worker \d+/, 5);

my $s = conn($h);
my (undef, undef, $m) = post($s, $sid, 2, 'resources/subscribe', { uri => 'books://1' });
ok(ref $m eq 'HASH' && $m->{result}, 'subscribe to books://1') or diag explain $m;

my ($owid) = sort { ($a eq $iwid) <=> ($b eq $iwid) } grep { $_ ne $spid } sort keys %$ON;
note("session made on $iwid, stream on $spid, touch from $owid");
my $other = $owid && $ON->{$owid};
SKIP: {
    skip 'no connection reached a second worker', 4 unless $other;
    (undef, undef, $m) = post($other, $sid, 3, 'tools/call', { name => 'touch', arguments => {} });
    is(text_of($m), "touched $owid", "touch runs on worker $owid");
    ($gbuf, $ok) = stream_wait($gs, qr/resources\/updated/, 5, $gbuf);
    ok($ok, 'the notification reaches the stream on the other worker');
    like($gbuf, qr/"uri":"books:\/\/1"/, 'naming the URI');

    my $same = $ON->{$spid};
    (undef, undef, $m) = post($same, $sid, 4, 'tools/call', { name => 'touch', arguments => {} }) if $same;
    ($gbuf) = stream_wait($gs, qr/(?:resources\/updated.*){2}/s, 3, $gbuf);
    ($gbuf) = stream_wait($gs, qr/(?!)/, 1, $gbuf);
    my $n = () = $gbuf =~ /resources\/updated/g;
    is($n, $same ? 2 : 1, 'each touch delivered once, none twice (self-delivery does not double up)');
}

($qbuf) = stream_wait($qs, qr/resources\/updated/, 1, $qbuf);
unlike($qbuf, qr/resources\/updated/, 'a session that did not subscribe hears nothing');

# ---- whether the bus delivers to its publisher ------------------------------------

(undef, undef, $m) = post(conn($h), $sid, 5, 'tools/call', { name => 'selfprobe', arguments => {} });
like(text_of($m), qr/^(?:self|not self)$/, 'the self-delivery probe answers');
note('Hyperman bus self-delivery in a pool: ' . text_of($m));

# ---- DELETE on another worker closes the stream ---------------------------------

($owid) = reverse grep { $_ ne $spid } sort keys %$ON;
$other = $owid && $ON->{$owid};
SKIP: {
    skip 'no connection reached a second worker', 2 unless $other;
    my ($dst) = request($other, 'DELETE', '/mcp', { 'Mcp-Session-Id' => $sid });
    is($dst, 204, 'DELETE on another worker');
    my (undef, undef, $closed) = stream_wait($gs, qr/(?!)/, 5, $gbuf);
    ok($closed, 'closes the stream held elsewhere');
}
($st) = post(conn($h), $sid, 6, 'tools/call', { name => 'pid', arguments => {} });
is($st, 404, 'and the session is gone on every worker');

# ---- a streamed POST on HTTP/1.1 -------------------------------------------------

(undef, $sid) = initialize($h);
my ($raw, $closed) = raw_request($h, 'POST', '/mcp',
    { Accept => 'application/json, text/event-stream', 'Mcp-Session-Id' => $sid },
    mcp_body(7, 'tools/call', { name => 'slow', arguments => {}, _meta => { progressToken => 'p' } }), 10);
like($raw, qr{Content-Type: text/event-stream}i, 'a stream => 1 tool streams');
like($raw, qr/notifications\/progress/, 'progress first');
like($raw, qr/^: ping/m, 'a heartbeat while the call waits');
like($raw, qr/slow done \d+/, 'then the answer');
ok($closed, 'and the server ends the connection');
ok(worker_of(conn($h), $sid) =~ /^\d+$/, 'a reconnect is served');

# ---- an OpenAPI tool whose handler returns a Future -------------------------------

(undef, undef, $m) = post(conn($h), $sid, 8, 'tools/call', { name => 'getbook', arguments => { id => '7' } });
my $book = eval { $JSON->decode(text_of($m)) } || {};
is($book->{id}, '7', 'the OpenAPI tool settles its Future on a live worker') or diag explain $m;
like($book->{pid} // '', qr/^\d+$/, 'answered by a worker');

my $log = stop_app($h);
unlike($log, qr/\b(?:panic|Segmentation|died|uncaught)\b/i, 'the pool logged no crash')
    or diag $log;

# ---- max_sessions counts across the pool ------------------------------------------

$h = spawn_app(live_source(max_sessions => 3), workers => 3);
my @made;
for (1 .. 3) { my ($st2, $id) = initialize($h); push @made, $st2 }
is_deeply(\@made, [200, 200, 200], 'three sessions under max_sessions => 3');
my (undef, undef, $hd);
($st, undef, $hd) = initialize($h);
is($st, 503, 'a fourth is 503, whichever worker takes it');
ok($hd->{'retry-after'}, 'with Retry-After');
stop_app($h);

done_testing;
