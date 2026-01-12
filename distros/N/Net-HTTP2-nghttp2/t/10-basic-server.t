#!/usr/bin/env perl
# Tests ported from python-hyper/h2 test_basic_logic.py TestBasicServer
# https://github.com/python-hyper/h2

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
    # Test: Server ignores client preamble string
    # (test_ignores_preamble from python-hyper/h2)
    #==========================================================================
    subtest 'server ignores client preamble' => sub {
        my @frames_received;
        my @headers_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    push @headers_received, [$stream_id, $name, $value];
                    return 0;
                },
                on_frame_recv => sub {
                    my ($frame) = @_;
                    push @frames_received, $frame;
                    return 0;
                },
            },
        );

        ok($session, "Created server session");

        # Send server connection preface
        $session->send_connection_preface();
        my $server_preface = $session->mem_send();
        ok(length($server_preface) > 0, "Server sent connection preface");

        # Client sends: preface string + empty SETTINGS frame
        my $client_data = CLIENT_PREFACE . build_settings_frame();

        my $consumed = $session->mem_recv($client_data);
        is($consumed, length($client_data), "Consumed all client data");

        # Should have received a SETTINGS frame
        my @settings_frames = grep { $_->{type} == FRAME_SETTINGS } @frames_received;
        ok(@settings_frames >= 1, "Received SETTINGS frame from client");

        done_testing;
    };

    #==========================================================================
    # Test: Server handles fragmented/drip-fed preamble
    # (test_drip_feed_preamble from python-hyper/h2)
    #==========================================================================
    subtest 'server handles drip-fed preamble' => sub {
        my @frames_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub {
                    my ($frame) = @_;
                    push @frames_received, $frame;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Send the preface one byte at a time
        my $client_data = CLIENT_PREFACE . build_settings_frame();
        my $total_consumed = 0;

        for my $byte (split //, $client_data) {
            my $consumed = $session->mem_recv($byte);
            $total_consumed += $consumed;
        }

        is($total_consumed, length($client_data), "Consumed all drip-fed data");

        # Should have received the SETTINGS frame
        my @settings_frames = grep { $_->{type} == FRAME_SETTINGS } @frames_received;
        ok(@settings_frames >= 1, "Received SETTINGS frame after drip-feed");

        done_testing;
    };

    #==========================================================================
    # Test: Server sends connection preface (SETTINGS frame)
    # (test_initiate_connection_sends_server_preamble from python-hyper/h2)
    #==========================================================================
    subtest 'server sends connection preface' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface(
            max_concurrent_streams => 100,
            initial_window_size    => 65535,
        );

        my $preface = $session->mem_send();
        ok(length($preface) >= 9, "Server preface is at least one frame");

        # Parse the frame
        my $header = parse_frame_header($preface);
        is($header->{type}, FRAME_SETTINGS, "First frame is SETTINGS");
        is($header->{stream_id}, 0, "SETTINGS frame on stream 0");
        ok(!($header->{flags} & FLAG_ACK), "SETTINGS frame is not ACK");

        done_testing;
    };

    #==========================================================================
    # Test: Server receives request headers
    # (test_headers_event from python-hyper/h2)
    #==========================================================================
    subtest 'server receives request headers' => sub {
        my @headers_received;
        my $stream_id_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id, $type, $flags) = @_;
                    $stream_id_received = $stream_id;
                    return 0;
                },
                on_header => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    push @headers_received, [$name, $value];
                    return 0;
                },
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Build a request
        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 1,
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        is($stream_id_received, 1, "Request arrived on stream 1");

        # Check headers
        my %headers = map { $_->[0] => $_->[1] } @headers_received;
        is($headers{':method'}, 'GET', "Method is GET");
        is($headers{':path'}, '/', "Path is /");
        is($headers{':scheme'}, 'https', "Scheme is https");
        is($headers{':authority'}, 'localhost', "Authority is localhost");

        done_testing;
    };

    #==========================================================================
    # Test: Server receives PING and sends ACK
    # (test_receiving_ping_frame from python-hyper/h2)
    #==========================================================================
    subtest 'server handles PING frame' => sub {
        my @frames_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub {
                    my ($frame) = @_;
                    push @frames_received, $frame;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $opaque_data = "pingpong";

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_ping_frame(opaque_data => $opaque_data);

        $session->mem_recv($client_data);

        # Get response - should include PING ACK
        my $response = $session->mem_send();
        ok(length($response) > 0, "Server sent response");

        # Parse response frames
        my ($frames, $remaining) = parse_frames($response);

        # Find PING ACK
        my @ping_acks = grep {
            $_->{type} == FRAME_PING && ($_->{flags} & FLAG_ACK)
        } @$frames;

        ok(@ping_acks >= 1, "Server sent PING ACK");
        is($ping_acks[0]->{payload}, $opaque_data, "PING ACK has same opaque data");

        done_testing;
    };

    #==========================================================================
    # Test: Server receives and acknowledges SETTINGS
    # (test_receiving_settings_frame_event and test_acknowledging_settings)
    #==========================================================================
    subtest 'server acknowledges settings' => sub {
        my @frames_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub {
                    my ($frame) = @_;
                    push @frames_received, $frame;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Client sends SETTINGS with specific values
        my $client_data = CLIENT_PREFACE
            . build_settings_frame(
                settings => {
                    SETTINGS_MAX_CONCURRENT_STREAMS() => 50,
                    SETTINGS_INITIAL_WINDOW_SIZE()    => 32768,
                },
            );

        $session->mem_recv($client_data);

        # Get response
        my $response = $session->mem_send();

        # Parse response frames
        my ($frames, $remaining) = parse_frames($response);

        # Find SETTINGS ACK
        my @settings_acks = grep {
            $_->{type} == FRAME_SETTINGS && ($_->{flags} & FLAG_ACK)
        } @$frames;

        ok(@settings_acks >= 1, "Server sent SETTINGS ACK");
        is($settings_acks[0]->{length}, 0, "SETTINGS ACK has empty payload");

        done_testing;
    };

    #==========================================================================
    # Test: Server can send GOAWAY
    # (test_close_connection from python-hyper/h2)
    #==========================================================================
    subtest 'server can close connection with GOAWAY' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        my $initial = $session->mem_send();

        # Process client preface
        $session->mem_recv(CLIENT_PREFACE . build_settings_frame());
        $session->mem_send();  # Send SETTINGS ACK

        # Terminate session
        $session->terminate_session(ERROR_NO_ERROR);

        my $response = $session->mem_send();
        ok(length($response) > 0, "Server sent GOAWAY");

        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Found GOAWAY frame");

        if (@goaway_frames) {
            my $goaway = $goaway_frames[0];
            is($goaway->{stream_id}, 0, "GOAWAY on stream 0");

            # Parse GOAWAY payload: last_stream_id (4 bytes) + error_code (4 bytes)
            my ($last_stream_id, $error_code) = unpack("N N", $goaway->{payload});
            is($error_code, ERROR_NO_ERROR, "GOAWAY with NO_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: Server receives DATA frames
    # (test_data_event from python-hyper/h2)
    #==========================================================================
    subtest 'server receives DATA frames' => sub {
        my @data_received;
        my $request_stream_id;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id) = @_;
                    $request_stream_id = $stream_id;
                    return 0;
                },
                on_header => sub { return 0; },
                on_frame_recv => sub { return 0; },
                on_data_chunk_recv => sub {
                    my ($stream_id, $data, $flags) = @_;
                    push @data_received, [$stream_id, $data];
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Build a POST request with body
        my $header_block = encode_headers([
            [':method', 'POST'],
            [':path', '/upload'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
            ['content-type', 'text/plain'],
        ]);

        my $body = "Hello, World!";

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 0,  # More data coming
                end_headers  => 1,
            )
            . build_data_frame(
                stream_id  => 1,
                data       => $body,
                end_stream => 1,
            );

        $session->mem_recv($client_data);

        is($request_stream_id, 1, "Request on stream 1");
        is(scalar(@data_received), 1, "Received one data chunk");
        is($data_received[0][0], 1, "Data on stream 1");
        is($data_received[0][1], $body, "Received correct body");

        done_testing;
    };

    #==========================================================================
    # Test: Server handles stream reset
    # (test_reset_stream from python-hyper/h2)
    #==========================================================================
    subtest 'server handles RST_STREAM' => sub {
        my @streams_closed;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
                on_stream_close  => sub {
                    my ($stream_id, $error_code) = @_;
                    push @streams_closed, [$stream_id, $error_code];
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Start a request
        my $header_block = encode_headers([
            [':method', 'GET'],
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
            . build_rst_stream_frame(
                stream_id  => 1,
                error_code => ERROR_CANCEL,
            );

        $session->mem_recv($client_data);

        ok(@streams_closed >= 1, "Stream was closed");
        is($streams_closed[0][0], 1, "Stream 1 was closed");
        is($streams_closed[0][1], ERROR_CANCEL, "Closed with CANCEL error");

        done_testing;
    };

    #==========================================================================
    # Test: Server handles WINDOW_UPDATE
    # (test_window_update_no_stream and test_window_update_with_stream)
    #==========================================================================
    subtest 'server handles WINDOW_UPDATE' => sub {
        my @frames_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub {
                    my ($frame) = @_;
                    push @frames_received, $frame;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Connection-level WINDOW_UPDATE
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_window_update_frame(
                stream_id => 0,
                increment => 65535,
            );

        my $consumed = $session->mem_recv($client_data);
        is($consumed, length($client_data), "Consumed WINDOW_UPDATE");

        my @window_updates = grep { $_->{type} == FRAME_WINDOW_UPDATE } @frames_received;
        ok(@window_updates >= 1, "Received WINDOW_UPDATE frame");
        is($window_updates[0]->{stream_id}, 0, "WINDOW_UPDATE on connection level");

        done_testing;
    };

    #==========================================================================
    # Test: want_read and want_write
    #==========================================================================
    subtest 'want_read and want_write' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        # Initially, session should want to read (waiting for client preface)
        ok($session->want_read(), "Session wants to read initially");

        # Send connection preface
        $session->send_connection_preface();
        ok($session->want_write(), "Session wants to write after submit_settings");

        # Drain the write buffer
        $session->mem_send();

        # Now feed it client data
        $session->mem_recv(CLIENT_PREFACE . build_settings_frame());

        # Should want to write (SETTINGS ACK)
        ok($session->want_write(), "Session wants to write SETTINGS ACK");

        done_testing;
    };
}

done_testing;
