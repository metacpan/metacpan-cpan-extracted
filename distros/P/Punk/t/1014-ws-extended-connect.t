#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use IO::Socket::INET;
use IO::Select;
use Time::HiRes ();
use Punk::Test ();
use Hyperman;

# WebSocket over HTTP/2 through Extended CONNECT (RFC 8441).
#
# The handshake is new and the codec is not - that split is the whole design.
# There is no 101, no Upgrade header, no Sec-WebSocket-Key and no Accept
# token; the server advertising ENABLE_CONNECT_PROTOCOL is the negotiation,
# and the answer is a 200. Once the stream is open the RFC 6455 framing
# running over it is byte for byte what the HTTP/1.1 path uses.
#
# Nothing available speaks this - curl's WebSocket is HTTP/1.1 only and
# h2load has none - so the client is written out here: HTTP/2 frames with
# literal HPACK, carrying WebSocket frames masked by hand.

plan skip_all => 'nghttp2 support not built' unless Hyperman->has_http2;

my ($port) = Punk::Test::free_ports(1)
    if Punk::Test->can('free_ports');
unless ($port) {
    # Punk::Test has no port helper here; ask the kernel directly.
    my $s = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                  Proto => 'tcp', Listen => 5, ReuseAddr => 1);
    plan skip_all => 'no free loopback port' unless $s;
    $port = $s->sockport;
    close $s;
}

my $app = <<'APP';
package WSApp;
use Punk;

websocket '/chat' => sub {
    my ($c, $ws) = @_;
    return unless $ws;
    $ws->on(message => sub {
        my ($conn, $msg) = @_;
        $conn->send("echo:$msg");
    });
};

1;
APP

my $dir = "punk_wsec_$$";
mkdir $dir or plan skip_all => "cannot make $dir";
open my $fh, '>', "$dir/WSApp.pm" or plan skip_all => 'cannot write the app';
print $fh $app;
close $fh;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    if (my $tb = eval { Test::Builder->new }) {
        for my $h (eval { $tb->output }, eval { $tb->failure_output },
                   eval { $tb->todo_output }) {
            eval { close $h } if $h;
        }
    }
    alarm 120;
    unshift @INC, $dir;
    require WSApp;
    Hyperman->run(app => WSApp->to_app, host => '127.0.0.1',
                  port => $port, workers => 1, http2 => 1);
    exit 0;
}

# ---- a minimal HTTP/2 client ---------------------------------------------

sub frame {
    my ($type, $flags, $sid, $pay) = @_;
    my $l = length $pay;
    pack('CCCCCN', ($l >> 16) & 0xff, ($l >> 8) & 0xff, $l & 0xff,
         $type, $flags, $sid) . $pay;
}
sub lit { my ($n, $v) = @_; "\x00" . chr(length $n) . $n . chr(length $v) . $v }

sub read_frame {
    my ($s, $t) = @_;
    my $sel = IO::Select->new($s);
    my $hdr = '';
    while (length($hdr) < 9) {
        return unless $sel->can_read($t || 5);
        my $n = sysread($s, my $b, 9 - length $hdr) or return;
        $hdr .= $b;
    }
    my ($a, $b2, $c, $type, $flags, $sid) = unpack('CCCCCN', $hdr);
    my $len = ($a << 16) | ($b2 << 8) | $c;
    my $pay = '';
    while (length($pay) < $len) {
        return unless $sel->can_read($t || 5);
        my $n = sysread($s, my $x, $len - length $pay) or return;
        $pay .= $x;
    }
    return ($type, $flags, $sid & 0x7fffffff, $pay);
}

# RFC 6455: a client frame is always masked, and the mask is a plain XOR.
sub ws_text {
    my ($payload) = @_;
    my $mask = pack('N', 0x5a5a5a5a);
    my $len  = length $payload;
    die "test frame too long" if $len > 125;
    my $masked = $payload ^ (substr($mask x (int($len / 4) + 1), 0, $len));
    return "\x81" . chr(0x80 | $len) . $mask . $masked;
}

# Server frames are never masked, so decoding one is just the header.
sub ws_decode {
    my ($buf) = @_;
    return unless length $buf >= 2;
    my $op  = ord(substr($buf, 0, 1)) & 0x0f;
    my $len = ord(substr($buf, 1, 1)) & 0x7f;
    return if $len > 125 || length($buf) < 2 + $len;
    return ($op, substr($buf, 2, $len));
}

my $sock;
for (1 .. 100) {
    $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                  Proto => 'tcp');
    last if $sock;
    Time::HiRes::sleep(0.05);
}
ok($sock, 'connected to the Punk app over TCP') or do {
    kill 'TERM', $pid; waitpid $pid, 0;
    unlink "$dir/WSApp.pm"; rmdir $dir;
    done_testing(); exit;
};

syswrite $sock, "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n";
syswrite $sock, frame(0x4, 0, 0, '');
for (1 .. 6) {
    my ($type, $flags) = read_frame($sock);
    last unless defined $type;
    last if $type == 0x4 && !($flags & 0x1);
}
syswrite $sock, frame(0x4, 0x1, 0, '');

# The Extended CONNECT: CONNECT plus :protocol, and no END_STREAM.
my $hb = lit(':method', 'CONNECT') . lit(':protocol', 'websocket')
       . lit(':scheme', 'http')    . lit(':path', '/chat')
       . lit(':authority', "127.0.0.1:$port");
syswrite $sock, frame(0x1, 0x4, 1, $hb);

my ($saw_headers, $ws_bytes) = (0, '');
syswrite $sock, frame(0x0, 0, 1, ws_text('hello'));

for (1 .. 30) {
    my ($type, $flags, $sid, $pay) = read_frame($sock, 5);
    last unless defined $type;
    $saw_headers = 1 if $type == 0x1 && $sid == 1;
    $ws_bytes .= $pay if $type == 0x0 && $sid == 1;
    last if length $ws_bytes >= 2;
}

ok($saw_headers,
   'the route answered the CONNECT stream - a 200, not a 101, because a '
 . 'multiplexed transport has no 101');

my ($op, $payload) = ws_decode($ws_bytes);
is($op, 1, 'the reply is a WebSocket text frame, unmasked as a server frame');
is($payload, 'echo:hello',
   'the handler saw the message and its reply came back over the same '
 . 'HTTP/2 stream - the RFC 6455 codec is unchanged by the transport');

close $sock;
kill 'TERM', $pid;
waitpid $pid, 0;
unlink "$dir/WSApp.pm";
rmdir $dir;
done_testing();
