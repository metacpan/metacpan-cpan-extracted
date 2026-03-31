use strict;
use warnings;
use utf8;
$SIG{PIPE} = 'IGNORE';
use IO::Socket::INET;
use Test::More tests => 9;
use EV;
use Net::WebSocket::EVx;
use Net::EmptyPort 'empty_port';

BEGIN { use_ok('Net::WebSocket::EVx') };

# --- helpers ---

my @async_tests;
sub call_next_test { ( (shift @async_tests) or sub { EV::break(EV::BREAK_ALL()) } )->() }

sub make_pair {
    my (%opts) = @_;
    my $port = empty_port;
    my $listen = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => $port, Proto => 'tcp',
    ) or die "listen: $!";
    my $cli_sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Blocking => 0,
    ) or die "connect: $!";
    my $srv_sock = $listen->accept() or die "accept: $!";
    $srv_sock->blocking(0);
    $listen->close;
    my $server = Net::WebSocket::EVx->new({
        fh => $srv_sock, %{$opts{server} || {}},
    });
    my $client = Net::WebSocket::EVx->new({
        type => 'client', fh => $cli_sock, %{$opts{client} || {}},
    });
    return ($server, $client, $srv_sock, $cli_sock);
}

# =========================================================
# Test group 1: basic text message + fragmented binary
# (original tests, using async accept to exercise EV::once)
# =========================================================

my $port1 = empty_port;
my $server_sock = IO::Socket::INET->new(
    Listen => 5, LocalAddr => '127.0.0.1', LocalPort => $port1, Proto => 'tcp',
) or die 'Failed to bind server!';

my ($server1, $connected1);

EV::once $server_sock, EV::READ, 10, sub {
    $connected1 = $server_sock->accept();
    $connected1->blocking(0);
    $server1 = Net::WebSocket::EVx->new({
        fh => $connected1,
        on_frame_recv_start => sub {},
        on_frame_recv_chunk => sub {},
        on_frame_recv_end   => sub {},
        on_msg_recv         => sub {
            my ($rsv, $opcode, $msg, $status_code) = @_;
            if (($msg eq 'first test message test test Юникод') and $opcode == 1) {
                pass("client->server text message");
                call_next_test();
            }
            if (($msg eq 'DataChunkDataChunk2') and $opcode == 2) {
                pass("client->server fragmented binary");
                call_next_test();
            }
        },
        on_close => sub {},
    });
};

my $client_sock1 = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1', PeerPort => $port1, Proto => 'tcp', Blocking => 0,
) or die 'Failed to client connect!';

my $client1 = Net::WebSocket::EVx->new({
    type => 'client', fh => $client_sock1,
    on_frame_recv_start => sub {},
    on_frame_recv_chunk => sub {},
    on_frame_recv_end   => sub {},
    on_msg_recv => sub {},
    on_close => sub {},
    buffering => 0,
});

{
    my $state = 0;
    my $starter;
    sub fragment_gen {
        if ($state == 0) { $state++; return 'DataChunk' }
        elsif ($state == 1) {
            $starter = EV::once undef, 0, 0.8, sub {
                $state++;
                $client1->start_write;
            };
            $client1->stop_write;
            return '';
        } elsif ($state == 2) {
            return ('DataChunk2', WS_FRAGMENTED_EOF);
        }
    }
}

# =========================================================
# Test group 2: server-to-client send
# =========================================================

my ($srv2, $cli2, $srv2_sock, $cli2_sock);

my $test_server_send = sub {
    ($srv2, $cli2, $srv2_sock, $cli2_sock) = make_pair(
        client => {
            on_msg_recv => sub {
                my ($rsv, $opcode, $msg) = @_;
                if ($msg eq 'hello from server' && $opcode == 1) {
                    pass("server->client text message");
                    call_next_test();
                }
            },
            on_close => sub {},
        },
        server => {
            on_msg_recv => sub {},
            on_close => sub {},
        },
    );
    $srv2->queue_msg('hello from server', 1);
};

# =========================================================
# Test group 3: queue_msg_ex with RSV1
# =========================================================

my ($srv3, $cli3, $srv3_sock, $cli3_sock);

my $test_rsv1 = sub {
    ($srv3, $cli3, $srv3_sock, $cli3_sock) = make_pair(
        client => {
            on_msg_recv => sub {
                my ($rsv, $opcode, $msg) = @_;
                if ($rsv && $opcode == 2) {
                    pass("queue_msg_ex with RSV1");
                    call_next_test();
                }
            },
            on_close => sub {},
        },
        server => {
            on_msg_recv => sub {},
            on_close => sub {},
        },
    );
    $srv3->queue_msg_ex("binary-with-rsv", 2, WS_RSV1_BIT);
};

# =========================================================
# Test group 4: wait() callback fires when queue drains
# =========================================================

my ($srv4, $cli4, $srv4_sock, $cli4_sock);

my $test_wait = sub {
    ($srv4, $cli4, $srv4_sock, $cli4_sock) = make_pair(
        client => {
            on_msg_recv => sub {},
            on_close => sub {},
        },
        server => {
            on_msg_recv => sub {},
            on_close => sub {},
        },
    );
    $srv4->queue_msg("wait-test");
    $srv4->wait(sub {
        is($srv4->queued_count(), 0, "wait() fires when queue drains, queued_count is 0");
        call_next_test();
    });
};

# =========================================================
# Test group 5: close handshake
# =========================================================

my ($srv5, $cli5, $srv5_sock, $cli5_sock);

my $test_close = sub {
    ($srv5, $cli5, $srv5_sock, $cli5_sock) = make_pair(
        client => {
            on_msg_recv => sub {},
            on_close => sub {
                my ($code) = @_;
                pass("close handshake - client on_close fired");
                call_next_test();
            },
        },
        server => {
            on_msg_recv => sub {},
            on_close => sub {},
        },
    );
    $srv5->close(1000);
};

# =========================================================
# Test group 6: buffering => 0 routes data through on_frame_recv_chunk
# =========================================================

my ($srv6, $cli6, $srv6_sock, $cli6_sock);

my $test_nobuf = sub {
    my $chunk_data = '';
    ($srv6, $cli6, $srv6_sock, $cli6_sock) = make_pair(
        server => {
            buffering => 0,
            on_frame_recv_chunk => sub {
                my ($data) = @_;
                $chunk_data .= $data;
            },
            on_msg_recv => sub {
                my ($rsv, $opcode, $msg) = @_;
                ok(!defined($msg) || $msg eq '', "buffering=0: on_msg_recv gets no data");
                is($chunk_data, 'nobuf-test', "buffering=0: on_frame_recv_chunk gets data");
                call_next_test();
            },
            on_frame_recv_start => sub {},
            on_frame_recv_end => sub {},
            on_close => sub {},
        },
        client => {
            on_msg_recv => sub {},
            on_close => sub {},
        },
    );
    $cli6->queue_msg('nobuf-test');
};

# =========================================================
# Assemble and run
# =========================================================

@async_tests = (
    # group 1: original tests
    sub { $client1->queue_msg('first test message test test Юникод', 1) },
    sub { $client1->queue_fragmented(\&fragment_gen, 2) },
    # group 2-6
    $test_server_send,
    $test_rsv1,
    $test_wait,
    $test_close,
    $test_nobuf,
);

my $timeout = EV::timer 10, 0, sub { fail("test timeout"); EV::break(EV::BREAK_ALL()) };

call_next_test;

EV::run;
