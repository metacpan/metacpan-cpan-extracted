#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes ();
use PunkTest qw(hit);
use Punk::Test::WS qw(encode_client decode_ref handshake_request upgrade_env);

# The websocket codec's refusals, each answered with the close code RFC 6455
# gives it: a one-byte close payload, a close code off the list, a close
# reason that is not UTF-8, a continuation with nothing to continue, a new
# data frame inside a fragmented message, a message past the route's size
# limit in one frame and across fragments, text that is not UTF-8 in one
# frame and split across two, a reserved bit set, an unmasked client frame;
# a pong the handler listens for; the server's own close left unanswered
# until its timeout; a handler that dies at the upgrade; and the dispatch
# refusals and the blocking fallback, in process.

BEGIN {
    eval { require Hyperman; 1 } or plan skip_all => 'Hyperman required for these tests';
    eval { require Punk::WebSocket; 1 } or plan skip_all => 'Punk::WebSocket unavailable';
    plan skip_all => 'Hyperman 0.11+ (the detach ABI) required' unless Punk::WebSocket::_hm_available();
}

my $port = 25600 + ($$ % 300);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    package WSEdge;
    use Punk;
    websocket '/echo' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("echo:$_[1]") });
        $ws->on(pong    => sub { $_[0]->send("saw pong:$_[1]") });
        $ws->on(ping    => sub { $_[0]->send("saw ping:$_[1]") });
    };
    websocket '/small' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("got " . length $_[1]) });
    }, { max_message_size => 16 };
    websocket '/bye' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->close(4000, 'bye now') });
    };
    websocket '/dies' => sub { die "ws boom\n" };
    get '/plain' => sub { $_[0]->text('plain ok') };
    package main;
    Hyperman->run(app => WSEdge->to_app, host => '127.0.0.1', port => $port, workers => 1);
    exit 0;
}
for (1 .. 60) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub sock {
    my $s = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $s->autoflush(1);
    return $s;
}
sub read_headers {
    my ($s) = @_;
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (sysread $s, my $c, 1) { $buf .= $c; last if $buf =~ /\r\n\r\n\z/ }
        alarm 0;
    };
    return $buf;
}
sub ws_connect {
    my (%a) = @_;
    my $s = sock();
    my ($req, $key) = handshake_request(host => $host, %a);
    syswrite $s, $req;
    my $hdr = read_headers($s);
    return ($s, $hdr, $key);
}
sub read_frame {
    my ($s, $secs) = @_;
    my $buf = \${*$s}{ws_buf};
    $$buf //= '';
    my $f;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($secs // 5);
        while (1) {
            $f = decode_ref($$buf);
            last if $f && ref $f;
            my $n = sysread $s, my $c, 4096;
            last unless $n;
            $$buf .= $c;
        }
        alarm 0;
    };
    return undef unless ref $f;
    substr $$buf, 0, $f->{consumed}, '';
    return $f;
}
sub close_code {
    my ($f) = @_;
    return undef unless $f && $f->{opcode} == 8 && length $f->{payload} >= 2;
    return unpack 'n', $f->{payload};
}
# the refusal a frame earns: the server's close frame's code, then EOF
sub expect_close {
    my ($code, $name, $path, @frames) = @_;
    my ($s) = ws_connect(path => $path);
    syswrite $s, $_ for @frames;
    my $f;
    for (1 .. 4) {                      # skip any data frame queued before the close
        $f = read_frame($s);
        last if !$f || $f->{opcode} == 8;
    }
    is(close_code($f), $code, $name);
    syswrite $s, encode_client(opcode => 8, payload => pack('n', 1000));   # answer the close, as a client does
    my $closed = 0;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 10;
        while (1) {
            my $n = sysread $s, my $rest, 1024;
            if (!defined $n) { $closed = 1 if $!{ECONNRESET} || $!{EPIPE}; last }
            if ($n == 0) { $closed = 1; last }
        }
        alarm 0;
    };
    ok($closed, '...and the server closes the socket once the close is answered');
    close $s;
}

# ---- control frames ------------------------------------------------------------
{
    my ($s) = ws_connect(path => '/echo');
    syswrite $s, encode_client(opcode => 10, payload => 'late');
    my $f = read_frame($s);
    is($f && $f->{payload}, 'saw pong:late', 'a pong reaches a handler that listens for it');
    syswrite $s, encode_client(opcode => 9, payload => 'hey');
    $f = read_frame($s);
    is($f && $f->{opcode}, 10, 'a ping is answered first');
    $f = read_frame($s);
    is($f && $f->{payload}, 'saw ping:hey', 'and then handed to the listener');
    close $s;
}

# ---- close frames ----------------------------------------------------------------
expect_close(1002, 'a one-byte close payload is a protocol error', '/echo', encode_client(opcode => 8, payload => 'x'));
expect_close(1002, 'a close code off the list is a protocol error', '/echo', encode_client(opcode => 8, payload => pack('n', 999)));
expect_close(1007, 'a close reason that is not UTF-8 is an invalid payload', '/echo', encode_client(opcode => 8, payload => pack('n', 1000) . "\xff\xfe"));
{
    my ($s) = ws_connect(path => '/echo');
    syswrite $s, encode_client(opcode => 8, payload => pack('n', 1000) . "caf\xc3\xa9");
    my $f = read_frame($s);
    is(close_code($f), 1000, 'a close with a UTF-8 reason is echoed with its code');
    close $s;
}

# ---- fragmentation and size -------------------------------------------------------
expect_close(1002, 'a continuation with nothing to continue is a protocol error', '/echo', encode_client(opcode => 0, fin => 1, payload => 'tail'));
expect_close(1002, 'a new data frame inside a fragmented message is a protocol error', '/echo',
    encode_client(opcode => 1, fin => 0, payload => 'frag'), encode_client(opcode => 1, fin => 1, payload => 'again'));
expect_close(1009, 'one frame past the size limit is too big', '/small', encode_client(opcode => 1, payload => 'x' x 17));
expect_close(1009, 'fragments that add up past the limit are too big', '/small',
    encode_client(opcode => 1, fin => 0, payload => 'x' x 10), encode_client(opcode => 0, fin => 1, payload => 'y' x 10));
{
    my ($s) = ws_connect(path => '/small');
    syswrite $s, encode_client(opcode => 1, payload => 'x' x 16);
    my $f = read_frame($s);
    is($f && $f->{payload}, 'got 16', 'a message at the limit passes');
    close $s;
}

# ---- text that is not UTF-8 ---------------------------------------------------------
expect_close(1007, 'text that is not UTF-8 is an invalid payload', '/echo', encode_client(opcode => 1, payload => "\xff\xfe"));
expect_close(1007, 'a multibyte character left unfinished at the end is too', '/echo',
    encode_client(opcode => 1, fin => 0, payload => "\xe2\x82"), encode_client(opcode => 0, fin => 1, payload => 'a'));
{
    my ($s) = ws_connect(path => '/echo');
    syswrite $s, encode_client(opcode => 1, fin => 0, payload => "\xe2\x82");
    syswrite $s, encode_client(opcode => 0, fin => 1, payload => "\xac");
    my $f = read_frame($s);
    is($f && $f->{payload}, "echo:\xe2\x82\xac", 'a multibyte character split across fragments is judged whole');
    close $s;
}

# ---- malformed frames --------------------------------------------------------------
{
    my $rsv = encode_client(opcode => 1, payload => 'hi');
    substr($rsv, 0, 1) = chr(ord(substr($rsv, 0, 1)) | 0x40);
    expect_close(1002, 'a reserved bit set is a protocol error', '/echo', $rsv);
    my $unmasked = pack('C', 0x81) . pack('C', 2) . 'hi';
    expect_close(1002, 'an unmasked client frame is a protocol error', '/echo', $unmasked);
}

# ---- the server's close, left unanswered ----------------------------------------------
{
    my ($s) = ws_connect(path => '/bye');
    syswrite $s, encode_client(opcode => 1, payload => 'go');
    my $f = read_frame($s);
    is(close_code($f), 4000, 'the handler closes with its own code');
    is(substr($f->{payload}, 2), 'bye now', 'and reason');
    my $t0 = Time::HiRes::time();
    my $n;
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 15; $n = sysread $s, my $rest, 1024; alarm 0 };
    ok(defined $n && $n == 0, 'a client that never answers the close is dropped at the close timeout');
    cmp_ok(Time::HiRes::time() - $t0, '>=', 8, '...which is about ten seconds');
    close $s;
}

# ---- a handler that dies at the upgrade --------------------------------------------------
{
    my ($s, $hdr) = ws_connect(path => '/dies');
    like($hdr, qr{^HTTP/1\.1 101 }, 'a handler that dies has already been answered 101');
    my $f = read_frame($s);
    ok(!$f || $f->{opcode} == 8, 'and the connection ends, with a close frame or without');
    close $s;
    my $s2 = sock();
    syswrite $s2, "GET /plain HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5; while (sysread $s2, my $c, 4096) { $buf .= $c } alarm 0 };
    like($buf, qr/plain ok\z/, 'and the worker goes on serving');
}

kill 'TERM', $pid;
waitpid $pid, 0;

# ---- dispatch refusals and the blocking fallback, in process ------------------------------
{
    package WSInproc;
    use Punk;
    websocket '/ws' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("in:$_[1]"); $_[0]->close(1000, 'done') });
    };
    websocket '/blocking' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("blk:$_[1]"); $_[0]->close(1000, 'done') });
    }, { blocking => 1 };
    package main;
}
my $app = WSInproc->to_app;
{
    my ($env) = upgrade_env(path => '/ws');
    my $r = hit($app, method => 'POST', path => '/ws', env => { %$env, REQUEST_METHOD => 'POST' });
    is($r->[0], 405, 'a POST to a websocket route is 405, from the router');
    my %h;
    $r = hit($app, path => '/ws');
    is($r->[0], 400, 'a plain GET is not an upgrade');
    like(join('', @{ $r->[2] }), qr/not a websocket upgrade/, 'and says so');
    $r = hit($app, path => '/ws', env => { %$env, HTTP_SEC_WEBSOCKET_KEY => 'not base64!' });
    is($r->[0], 400, 'a key that is not 16 bytes of base64 is refused');
    like(join('', @{ $r->[2] }), qr/bad Sec-WebSocket-Key/, 'by name');
    $r = hit($app, path => '/ws', env => { %$env, HTTP_SEC_WEBSOCKET_VERSION => 8 });
    is($r->[0], 426, 'another websocket version is 426');
    %h = @{ $r->[1] };
    is($h{'Sec-WebSocket-Version'}, 13, 'naming the one that works');
    $r = hit($app, path => '/ws', env => { %$env, 'psgix.connect_protocol' => 'websocket' });
    is($r->[0], 400, 'extended CONNECT with a GET is refused');
    like(join('', @{ $r->[2] }), qr/uses CONNECT/, 'and told what to use');
    $r = hit($app, path => '/ws', env => $env);
    is($r->[0], 501, 'with no server ABI and no blocking option the upgrade is 501');
    like(join('', @{ $r->[2] }), qr/cannot upgrade websockets/, 'and says what it needs');
}
{
    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    $ours->autoflush(1);
    syswrite $ours, encode_client(opcode => 1, payload => 'hello');
    syswrite $ours, encode_client(opcode => 8, payload => pack('n', 1000));   # the blocking loop ends on the peer's close
    my ($env) = upgrade_env(path => '/blocking');
    my $r = hit($app, path => '/blocking', env => { %$env, 'psgix.io' => $theirs });
    is($r->[0], 200, 'the blocking fallback owns the socket and returns when it is done');
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5; while (sysread $ours, my $c, 4096) { $buf .= $c } alarm 0 };
    like($buf, qr{^HTTP/1\.1 101 }, 'the handshake went down the socket');
    my $f = decode_ref(substr($buf, index($buf, "\r\n\r\n") + 4));
    is($f && $f->{payload}, 'blk:hello', 'followed by the handler\'s reply');
}

done_testing;
