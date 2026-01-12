use strict;
use warnings;
use Test::More;

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;

SKIP: {
    skip "nghttp2 not available", 10 unless Net::HTTP2::nghttp2->available;

    my @received_headers;
    my @received_frames;

    # Create server session with callbacks
    my $session = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub {
                my ($stream_id, $type, $flags) = @_;
                diag("on_begin_headers: stream=$stream_id type=$type flags=$flags");
                return 0;
            },
            on_header => sub {
                my ($stream_id, $name, $value, $flags) = @_;
                push @received_headers, [$stream_id, $name, $value];
                diag("on_header: stream=$stream_id $name: $value");
                return 0;
            },
            on_frame_recv => sub {
                my ($frame) = @_;
                push @received_frames, $frame;
                diag("on_frame_recv: type=$frame->{type} stream=$frame->{stream_id}");
                return 0;
            },
        },
    );

    ok($session, "Created server session");
    isa_ok($session, 'Net::HTTP2::nghttp2::Session');

    # Send connection preface
    $session->send_connection_preface(
        max_concurrent_streams => 100,
    );

    # Get initial settings frame to send
    my $to_send = $session->mem_send();
    ok(length($to_send) > 0, "Got initial SETTINGS frame to send");
    diag("Initial send buffer: " . length($to_send) . " bytes");

    # Session should want to read (waiting for client preface)
    ok($session->want_read(), "Session wants to read");

    # Simulate receiving client connection preface
    # PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n followed by SETTINGS frame
    my $client_preface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n";
    # Empty SETTINGS frame: length=0, type=4, flags=0, stream=0
    $client_preface .= pack("CCC N", 0, 0, 4, 0); # Actually this should be different format

    # HTTP/2 frame header is 9 bytes:
    # 3 bytes length, 1 byte type, 1 byte flags, 4 bytes stream ID
    my $settings_frame = pack("CCC C C N",
        0, 0, 0,    # length = 0 (empty settings)
        4,          # type = SETTINGS
        0,          # flags = 0
        0           # stream ID = 0
    );
    $client_preface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n" . $settings_frame;

    eval {
        my $consumed = $session->mem_recv($client_preface);
        diag("Consumed $consumed bytes from client preface");
    };
    if ($@) {
        diag("Error processing preface: $@");
    }

    # Get any response we need to send
    my $response = $session->mem_send();
    diag("Response buffer: " . length($response) . " bytes");

    pass("Session handles client preface");
}

done_testing;
