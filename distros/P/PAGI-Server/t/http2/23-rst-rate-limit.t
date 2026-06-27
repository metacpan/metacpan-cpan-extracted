use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../../lib";

plan skip_all => "Server integration tests not supported on Windows" if $^O eq 'MSWin32';
BEGIN {
    eval { require Net::HTTP2::nghttp2; Net::HTTP2::nghttp2->VERSION(0.008); 1 }
        or plan(skip_all => 'Net::HTTP2::nghttp2 0.008+ not installed (optional)');
}

# ============================================================
# Test: HTTP/2 Rapid Reset (CVE-2023-44487) defense
# ============================================================
# nghttp2 >= 1.57 rate-limits inbound RST_STREAM frames with a token
# bucket; when the budget is exhausted it tears the connection down with
# a GOAWAY. PAGI::Server exposes this through the h2_rst_rate_limit =>
# { burst, rate } option, which threads down to Net::HTTP2::nghttp2's
# new_server(stream_reset_burst/stream_reset_rate).
#
# This is a DIFFERENTIAL test. A naive "flood RSTs -> assert a GOAWAY
# appeared" check is a trap: nghttp2 also emits a GOAWAY for unrelated
# reasons (e.g. a protocol error), so the test could pass for the wrong
# reason. We deliberately do NOT assert the GOAWAY error code (nghttp2
# uses INTERNAL_ERROR, not ENHANCE_YOUR_CALM, for this limit, and the
# binding does not surface the code on the frame anyway). Instead we run
# two cases against the SAME tiny-budget server config:
#   * exceed: open + RST MORE streams than the burst -> expect GOAWAY
#   * under : open + RST FEWER streams than the burst -> expect NO GOAWAY
# If GOAWAY appears only in the exceed case, the token bucket is the
# cause (a protocol error would fire in BOTH).

require PAGI::Server::Protocol::HTTP2;

plan skip_all => 'HTTP/2 (nghttp2) not available'
    unless PAGI::Server::Protocol::HTTP2->available;

# Default-on: omitting the option yields nghttp2's default budget (1000/33).
my $default_proto = PAGI::Server::Protocol::HTTP2->new;
is($default_proto->{h2_rst_rate_limit}, { burst => 1000, rate => 33 },
   'h2_rst_rate_limit defaults to burst 1000 / rate 33 (on by default)');

use constant NGHTTP2_GOAWAY => Net::HTTP2::nghttp2::NGHTTP2_GOAWAY();
use constant H2_CANCEL      => 8;   # RST_STREAM error code CANCEL (RFC 9113)

# Tiny budget so a handful of resets crosses the threshold deterministically.
# The bucket refills at RATE tokens per whole elapsed second; the test runs
# well within one second, so no refill occurs mid-run and the outcome is
# deterministic: BURST resets are absorbed, the next one underflows.
use constant BURST => 3;
use constant RATE  => 1;

# Complete the client<->server HTTP/2 handshake. Exchanges BOTH
# connection prefaces + SETTINGS/SETTINGS-ACK; omitting the server
# preface means zero bytes flow (learned in the binding work).
sub complete_handshake {
    my ($session, $client) = @_;

    my $server_data = $session->extract;

    $client->send_connection_preface;
    my $client_data = $client->mem_send;

    $session->feed($client_data);

    $client->mem_recv($server_data) if defined $server_data && length($server_data);

    my $server_ack = $session->extract;
    $client->mem_recv($server_ack) if defined $server_ack && length($server_ack);

    my $client_ack = $client->mem_send;
    $session->feed($client_ack) if defined $client_ack && length($client_ack);

    my $extra = $session->extract;
    $client->mem_recv($extra) if defined $extra && length($extra);
}

# Run ONE differential case: against a fresh tiny-budget PAGI server
# session, drive the Rapid Reset pattern (HEADERS then RST_STREAM on the
# same stream) $n_resets times. Returns true if the client ever saw a
# GOAWAY frame.
#
# Two driving subtleties make the resets actually reach nghttp2's
# RST_STREAM rate limiter:
#
#  1. The client flushes HEADERS and RST_STREAM as SEPARATE sends.
#     submit_rst_stream cancels any still-pending HEADERS for the same
#     stream (documented nghttp2 side effect); batching both before one
#     client send would drop the HEADERS, the stream would never open at
#     the server, and the reset would not count.
#
#  2. The server is fed HEADERS and RST_STREAM back-to-back WITHOUT
#     flushing the server's outgoing response in between. nghttp2 only
#     counts a reset of a stream that is still open; if the server's
#     response (with END_STREAM) were flushed first the stream would
#     already be closed and the reset would not count. Pipelining
#     HEADERS+RST faster than the server emits its response is exactly
#     the real Rapid Reset attack shape.
sub run_reset_storm {
    my ($n_resets) = @_;

    my $proto = PAGI::Server::Protocol::HTTP2->new(
        h2_rst_rate_limit => { burst => BURST, rate => RATE },
    );

    # Real PAGI callbacks: respond to each request so streams process
    # cleanly and the only thing under test is the RST rate limit.
    my $session;
    $session = $proto->create_session(
        on_request => sub {
            my ($stream_id) = @_;
            $session->submit_response($stream_id,
                status  => 200,
                headers => [['content-type', 'text/plain']],
                body    => "ok\n",
            );
        },
        on_body  => sub {},
        on_close => sub {},
    );

    my $saw_goaway = 0;
    my $client;
    $client = Net::HTTP2::nghttp2::Session->new_client(
        callbacks => {
            on_begin_headers   => sub { 0 },
            on_header          => sub { 0 },
            on_frame_recv      => sub {
                my ($frame) = @_;
                $saw_goaway = 1 if $frame->{type} == NGHTTP2_GOAWAY;
                return 0;
            },
            on_data_chunk_recv => sub { 0 },
            on_stream_close    => sub { 0 },
        },
    );

    complete_handshake($session, $client);

    # Drain all queued server output to the client.
    my $pump = sub {
        while (1) {
            my $in = $session->extract;
            last unless defined $in && length($in);
            $client->mem_recv($in);
        }
    };

    for (1 .. $n_resets) {
        # 1. Open the stream: flush HEADERS so the server registers it.
        my $stream_id = $client->submit_request(
            method    => 'GET',
            path      => '/',
            scheme    => 'https',
            authority => 'localhost',
        );
        my $headers = $client->mem_send;
        $session->feed($headers) if defined $headers && length($headers);

        # 2. Reset the still-open stream before draining the server's
        #    response, so the reset lands while the stream is in flight.
        $client->submit_rst_stream($stream_id, H2_CANCEL);
        my $rst = $client->mem_send;
        $session->feed($rst) if defined $rst && length($rst);

        # Now drain server -> client; a GOAWAY surfaces here once the
        # RST_STREAM budget is exhausted.
        $pump->();
    }

    return $saw_goaway;
}

# ------------------------------------------------------------
# Control: stay UNDER the burst -> no GOAWAY.
# ------------------------------------------------------------
my $under_goaway = run_reset_storm(BURST - 1);
ok(!$under_goaway,
    'under-budget reset storm does NOT trigger GOAWAY (control)');

# ------------------------------------------------------------
# Exceed the burst -> GOAWAY (the rate limiter fires).
# ------------------------------------------------------------
my $exceed_goaway = run_reset_storm(BURST * 10);
ok($exceed_goaway,
    'over-budget reset storm triggers GOAWAY (rate limiter fired)');

# The differential is the actual proof: GOAWAY in exceed but not under
# means it was the rate limiter, not an unrelated protocol error.
ok($exceed_goaway && !$under_goaway,
    'GOAWAY appears only when the RST_STREAM budget is exceeded');

done_testing;
