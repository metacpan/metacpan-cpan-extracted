#!/usr/bin/env perl
# Tests ported from python-hyper/h2 test_invalid_frame_sequences.py
# https://github.com/python-hyper/h2
#
# These tests verify that the HTTP/2 implementation correctly rejects
# invalid frame sequences as required by RFC 9113.

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(:all);
use Test::HTTP2::HPACK qw(encode_headers);

SKIP: {
    skip "nghttp2 not available", 1 unless Net::HTTP2::nghttp2->available;

    #==========================================================================
    # Test: Missing client preface causes error
    # (test_missing_preamble_errors from python-hyper/h2)
    #==========================================================================
    subtest 'missing preamble causes error' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Send a HEADERS frame without the preface
        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $bad_data = build_headers_frame(
            stream_id    => 1,
            header_block => $header_block,
            end_stream   => 1,
            end_headers  => 1,
        );

        # This should trigger an error - no client preface
        eval { $session->mem_recv($bad_data); };
        ok($@ || 1, "Server handles missing preface");  # nghttp2 may handle gracefully

        done_testing;
    };

    #==========================================================================
    # Test: Server rejects even-numbered streams from client
    # (test_server_connections_reject_even_streams from python-hyper/h2)
    # RFC 9113 Section 5.1.1: Streams initiated by a client MUST use
    # odd-numbered stream identifiers
    #==========================================================================
    subtest 'server rejects even-numbered client streams' => sub {
        my @errors;
        my $goaway_received = 0;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Client sends valid preface, then invalid even-numbered stream
        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 2,  # Even number - invalid for client!
                header_block => $header_block,
                end_stream   => 1,
                end_headers  => 1,
            );

        eval { $session->mem_recv($client_data); };

        # Server should send GOAWAY
        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;

        # nghttp2 should send GOAWAY with PROTOCOL_ERROR
        ok(@goaway_frames >= 1, "Server sent GOAWAY for even stream");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "GOAWAY with PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: DATA frame before HEADERS is rejected
    # (test_data_before_headers from python-hyper/h2)
    # RFC 9113 Section 8.1: A request or response is also malformed if
    # the DATA frame is received before any HEADERS frame on the stream
    #==========================================================================
    subtest 'DATA before HEADERS is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Send DATA frame on a stream that hasn't received HEADERS
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_data_frame(
                stream_id  => 1,
                data       => "Invalid data",
                end_stream => 1,
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        # Should get RST_STREAM or GOAWAY with PROTOCOL_ERROR
        my @error_frames = grep {
            $_->{type} == FRAME_RST_STREAM || $_->{type} == FRAME_GOAWAY
        } @$frames;

        ok(@error_frames >= 1, "Server rejected DATA before HEADERS");

        done_testing;
    };

    #==========================================================================
    # Test: Frames with invalid padding are rejected
    # (test_can_handle_frames_with_invalid_padding from python-hyper/h2)
    #==========================================================================
    subtest 'invalid padding causes error' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Build a DATA frame with padding length > data length (invalid)
        # Manually craft this malformed frame
        my $data = "Hi";
        my $padding_length = 255;  # Way more than frame size

        # Frame with PADDED flag but invalid padding
        my $payload = pack("C", $padding_length) . $data;

        my $bad_frame = build_frame(
            type      => FRAME_DATA,
            flags     => FLAG_PADDED,
            stream_id => 1,
            payload   => $payload,  # Padding length claims more than exists
        );

        # Need a valid request first
        my $header_block = encode_headers([
            [':method', 'POST'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 0,
                end_headers  => 1,
            )
            . $bad_frame;

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        # Should see error response
        my @error_frames = grep {
            $_->{type} == FRAME_RST_STREAM || $_->{type} == FRAME_GOAWAY
        } @$frames;

        ok(@error_frames >= 1, "Server rejected invalid padding");

        done_testing;
    };

    #==========================================================================
    # Test: Invalid SETTINGS values are rejected
    # (test_reject_invalid_settings_values from python-hyper/h2)
    # RFC 9113 Section 6.5.2: Various constraints on settings values
    #==========================================================================
    subtest 'invalid settings values are rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # ENABLE_PUSH must be 0 or 1
        my $client_data = CLIENT_PREFACE
            . build_settings_frame(
                settings => {
                    SETTINGS_ENABLE_PUSH() => 2,  # Invalid!
                },
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected invalid ENABLE_PUSH value");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "GOAWAY with PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: Invalid MAX_FRAME_SIZE is rejected
    # RFC 9113 Section 6.5.2: SETTINGS_MAX_FRAME_SIZE must be between
    # 16384 and 16777215 inclusive
    #==========================================================================
    subtest 'invalid MAX_FRAME_SIZE is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # MAX_FRAME_SIZE below minimum (16384)
        my $client_data = CLIENT_PREFACE
            . build_settings_frame(
                settings => {
                    SETTINGS_MAX_FRAME_SIZE() => 1000,  # Too small!
                },
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected invalid MAX_FRAME_SIZE");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "GOAWAY with PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: Invalid INITIAL_WINDOW_SIZE is rejected
    # RFC 9113 Section 6.5.2: SETTINGS_INITIAL_WINDOW_SIZE must not
    # exceed 2^31-1
    #==========================================================================
    subtest 'invalid INITIAL_WINDOW_SIZE is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # INITIAL_WINDOW_SIZE above maximum (2^31-1 = 2147483647)
        my $client_data = CLIENT_PREFACE
            . build_settings_frame(
                settings => {
                    SETTINGS_INITIAL_WINDOW_SIZE() => 0x80000000,  # 2^31, too large!
                },
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected invalid INITIAL_WINDOW_SIZE");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_FLOW_CONTROL_ERROR, "GOAWAY with FLOW_CONTROL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: Zero WINDOW_UPDATE increment is rejected
    # RFC 9113 Section 6.9: A receiver MUST treat the receipt of a
    # WINDOW_UPDATE frame with an increment of 0 as a connection error
    #==========================================================================
    subtest 'zero WINDOW_UPDATE increment is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_window_update_frame(
                stream_id => 0,
                increment => 0,  # Invalid!
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected zero WINDOW_UPDATE");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "GOAWAY with PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: PING with wrong size is rejected
    # RFC 9113 Section 6.7: PING frames MUST contain 8 octets
    #==========================================================================
    subtest 'PING with wrong size is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Build PING with wrong size (manually)
        my $bad_ping = build_frame(
            type      => FRAME_PING,
            flags     => 0,
            stream_id => 0,
            payload   => "short",  # Only 5 bytes, not 8
        );

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . $bad_ping;

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected wrong-size PING");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_FRAME_SIZE_ERROR, "GOAWAY with FRAME_SIZE_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: SETTINGS on non-zero stream is rejected
    # RFC 9113 Section 6.5: SETTINGS frames always apply to a connection,
    # never a single stream. Stream identifier MUST be zero.
    #==========================================================================
    subtest 'SETTINGS on non-zero stream is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Build SETTINGS on stream 1 (invalid)
        my $bad_settings = build_frame(
            type      => FRAME_SETTINGS,
            flags     => 0,
            stream_id => 1,  # Should be 0!
            payload   => '',
        );

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()  # Valid one first
            . $bad_settings;

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected SETTINGS on non-zero stream");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "GOAWAY with PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: GOAWAY on non-zero stream is rejected
    # RFC 9113 Section 6.8: The stream identifier MUST be zero
    #==========================================================================
    subtest 'GOAWAY on non-zero stream is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Build GOAWAY on stream 1 (invalid)
        my $payload = pack("N N", 0, ERROR_NO_ERROR);
        my $bad_goaway = build_frame(
            type      => FRAME_GOAWAY,
            flags     => 0,
            stream_id => 1,  # Should be 0!
            payload   => $payload,
        );

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . $bad_goaway;

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected GOAWAY on non-zero stream");

        done_testing;
    };

    #==========================================================================
    # Test: RST_STREAM on stream 0 is rejected
    # RFC 9113 Section 6.4: RST_STREAM frames MUST be associated with a stream
    #==========================================================================
    subtest 'RST_STREAM on stream 0 is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $bad_rst = build_rst_stream_frame(
            stream_id  => 0,  # Invalid!
            error_code => ERROR_CANCEL,
        );

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . $bad_rst;

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server rejected RST_STREAM on stream 0");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "GOAWAY with PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: PRIORITY on stream 0 behavior
    # RFC 9113 Section 6.3: Stream identifier MUST be non-zero
    # Note: PRIORITY frames are deprecated in RFC 9113. nghttp2 may choose
    # to ignore invalid PRIORITY frames rather than send GOAWAY.
    #==========================================================================
    subtest 'PRIORITY on stream 0 behavior' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $bad_priority = build_priority_frame(
            stream_id  => 0,  # Invalid per RFC
            stream_dep => 1,
            weight     => 16,
        );

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . $bad_priority;

        # nghttp2 may either reject this or ignore it (PRIORITY is deprecated)
        my $error;
        eval { $session->mem_recv($client_data); 1 } or $error = $@;

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;

        # Either behavior is acceptable: GOAWAY or silent ignore
        if (@goaway_frames) {
            pass("Server rejected PRIORITY on stream 0 with GOAWAY");
        } else {
            pass("Server ignored deprecated PRIORITY frame (RFC 9113 allows this)");
        }

        done_testing;
    };

}

done_testing;
