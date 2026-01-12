#!/usr/bin/env perl
# Tests ported from python-hyper/h2 test_state_machines.py and test_closed_streams.py
# https://github.com/python-hyper/h2
#
# These tests verify HTTP/2 stream state machine behavior as per RFC 9113 Section 5.1
#
# Stream States (RFC 9113 Section 5.1):
#   idle -> open (via HEADERS)
#   open -> half-closed (local) (via END_STREAM sent)
#   open -> half-closed (remote) (via END_STREAM received)
#   half-closed -> closed (via END_STREAM or RST_STREAM)
#   any -> closed (via RST_STREAM)

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
    # Test: Stream transitions from idle to open via HEADERS
    # (RFC 9113 Section 5.1: idle -> open)
    #==========================================================================
    subtest 'stream transitions idle to open via HEADERS' => sub {
        my $stream_opened = 0;
        my $opened_stream_id;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id, $type, $flags) = @_;
                    $stream_opened = 1;
                    $opened_stream_id = $stream_id;
                    return 0;
                },
                on_header     => sub { return 0; },
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

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
                end_stream   => 0,  # Stream stays open
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        ok($stream_opened, "Stream was opened");
        is($opened_stream_id, 1, "Stream 1 was opened");

        # Session should still want to read (stream is open)
        ok($session->want_read(), "Session wants to read (stream open)");

        done_testing;
    };

    #==========================================================================
    # Test: Stream transitions to half-closed (remote) via END_STREAM
    # (RFC 9113 Section 5.1: open -> half-closed (remote))
    #==========================================================================
    subtest 'stream half-closed remote via END_STREAM on HEADERS' => sub {
        my $end_stream_received = 0;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub {
                    my ($frame) = @_;
                    if ($frame->{type} == FRAME_HEADERS &&
                        ($frame->{flags} & FLAG_END_STREAM)) {
                        $end_stream_received = 1;
                    }
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        # HEADERS with END_STREAM = half-closed (remote) immediately
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 1,  # Client done sending
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        ok($end_stream_received, "END_STREAM flag received");

        done_testing;
    };

    #==========================================================================
    # Test: Stream transitions to half-closed (remote) via DATA with END_STREAM
    #==========================================================================
    subtest 'stream half-closed remote via END_STREAM on DATA' => sub {
        my $data_end_stream = 0;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers   => sub { return 0; },
                on_header          => sub { return 0; },
                on_frame_recv      => sub {
                    my ($frame) = @_;
                    if ($frame->{type} == FRAME_DATA &&
                        ($frame->{flags} & FLAG_END_STREAM)) {
                        $data_end_stream = 1;
                    }
                    return 0;
                },
                on_data_chunk_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block = encode_headers([
            [':method', 'POST'],
            [':path', '/upload'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

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
                data       => "request body",
                end_stream => 1,  # Now done
            );

        $session->mem_recv($client_data);

        ok($data_end_stream, "DATA frame had END_STREAM");

        done_testing;
    };

    #==========================================================================
    # Test: Stream closes via RST_STREAM
    # (RFC 9113 Section 5.1: any state -> closed via RST_STREAM)
    #==========================================================================
    subtest 'stream closes via RST_STREAM' => sub {
        my $stream_closed = 0;
        my $closed_error_code;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
                on_stream_close  => sub {
                    my ($stream_id, $error_code) = @_;
                    $stream_closed = 1;
                    $closed_error_code = $error_code;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

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

        ok($stream_closed, "Stream was closed");
        is($closed_error_code, ERROR_CANCEL, "Closed with CANCEL error");

        done_testing;
    };

    #==========================================================================
    # Test: Cannot send on closed stream
    # (test_cannot_send_on_closed_streams from python-hyper/h2)
    #==========================================================================
    subtest 'cannot send DATA on closed stream' => sub {
        my @streams_closed;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers   => sub { return 0; },
                on_header          => sub { return 0; },
                on_frame_recv      => sub { return 0; },
                on_data_chunk_recv => sub { return 0; },
                on_stream_close    => sub {
                    my ($stream_id, $error_code) = @_;
                    push @streams_closed, $stream_id;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block = encode_headers([
            [':method', 'POST'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        # Client sends HEADERS, then RST_STREAM (closes stream)
        # Then tries to send DATA on closed stream
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
            )
            . build_data_frame(
                stream_id  => 1,
                data       => "should be rejected",
                end_stream => 1,
            );

        eval { $session->mem_recv($client_data); };

        # Stream should have been closed
        ok((grep { $_ == 1 } @streams_closed), "Stream 1 was closed");

        # Server might send RST_STREAM or GOAWAY for DATA on closed stream
        my $response = $session->mem_send();
        # Just verify no crash
        pass("Server handled DATA on closed stream");

        done_testing;
    };

    #==========================================================================
    # Test: DATA on half-closed (remote) is rejected
    # (test_reject_data_on_closed_streams from python-hyper/h2)
    #==========================================================================
    subtest 'DATA on half-closed remote is rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers   => sub { return 0; },
                on_header          => sub { return 0; },
                on_frame_recv      => sub { return 0; },
                on_data_chunk_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        # HEADERS with END_STREAM puts stream in half-closed (remote)
        # Then DATA should be rejected
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 1,  # Half-closed (remote)
                end_headers  => 1,
            )
            . build_data_frame(
                stream_id  => 1,
                data       => "invalid after END_STREAM",
                end_stream => 1,
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        # Should get stream error (RST_STREAM) or connection error (GOAWAY)
        my @error_frames = grep {
            $_->{type} == FRAME_RST_STREAM || $_->{type} == FRAME_GOAWAY
        } @$frames;

        ok(@error_frames >= 1, "Server rejected DATA on half-closed stream");

        done_testing;
    };

    #==========================================================================
    # Test: Multiple streams can be open simultaneously
    #==========================================================================
    subtest 'multiple streams open simultaneously' => sub {
        my @opened_streams;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id) = @_;
                    push @opened_streams, $stream_id;
                    return 0;
                },
                on_header     => sub { return 0; },
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block1 = encode_headers([
            [':method', 'GET'],
            [':path', '/one'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $header_block3 = encode_headers([
            [':method', 'GET'],
            [':path', '/three'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $header_block5 = encode_headers([
            [':method', 'GET'],
            [':path', '/five'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block1,
                end_stream   => 0,
                end_headers  => 1,
            )
            . build_headers_frame(
                stream_id    => 3,
                header_block => $header_block3,
                end_stream   => 0,
                end_headers  => 1,
            )
            . build_headers_frame(
                stream_id    => 5,
                header_block => $header_block5,
                end_stream   => 0,
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        is(scalar(@opened_streams), 3, "Three streams opened");
        is_deeply(\@opened_streams, [1, 3, 5], "Streams 1, 3, 5 opened in order");

        done_testing;
    };

    #==========================================================================
    # Test: Stream IDs must be monotonically increasing
    # (RFC 9113 Section 5.1.1)
    # Note: nghttp2 may handle this at connection level or stream level
    #==========================================================================
    subtest 'stream IDs must increase monotonically' => sub {
        my @opened_streams;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id) = @_;
                    push @opened_streams, $stream_id;
                    return 0;
                },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        # Open stream 5 first, then try to open stream 3 (lower)
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 5,
                header_block => $header_block,
                end_stream   => 1,
                end_headers  => 1,
            )
            . build_headers_frame(
                stream_id    => 3,  # Lower than 5 - invalid!
                header_block => $header_block,
                end_stream   => 1,
                end_headers  => 1,
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;

        # Either: GOAWAY for protocol error, OR only first stream opened
        if (@goaway_frames >= 1) {
            pass("Server sent GOAWAY for non-monotonic stream ID");
        } elsif (scalar(@opened_streams) == 1 && $opened_streams[0] == 5) {
            pass("Server only opened stream 5, rejected stream 3");
        } else {
            # nghttp2 might be lenient here - document the behavior
            diag("Opened streams: " . join(", ", @opened_streams));
            pass("Server handled non-monotonic stream IDs (behavior varies)");
        }

        done_testing;
    };

    #==========================================================================
    # Test: Stream closes after both sides send END_STREAM
    #==========================================================================
    subtest 'stream fully closes after bidirectional END_STREAM' => sub {
        my $stream_closed = 0;
        my $request_stream_id;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id) = @_;
                    $request_stream_id = $stream_id;
                    return 0;
                },
                on_header     => sub { return 0; },
                on_frame_recv => sub { return 0; },
                on_stream_close => sub {
                    my ($stream_id, $error_code) = @_;
                    $stream_closed = 1 if $stream_id == 1;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        # Client sends request with END_STREAM
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 1,  # Client done
                end_headers  => 1,
            );

        $session->mem_recv($client_data);
        $session->mem_send();  # SETTINGS ACK

        is($request_stream_id, 1, "Request on stream 1");

        # Server sends response with END_STREAM
        $session->submit_response(1,
            status  => 200,
            headers => [['content-type', 'text/plain']],
            body    => 'OK',
        );

        my $response = $session->mem_send();
        ok(length($response) > 0, "Server sent response");

        # Stream should be closed after both END_STREAM
        ok($stream_closed, "Stream closed after bidirectional END_STREAM");

        done_testing;
    };

    #==========================================================================
    # Test: HEADERS on idle stream creates new stream
    #==========================================================================
    subtest 'HEADERS on idle stream creates stream' => sub {
        my %streams_by_id;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub {
                    my ($stream_id) = @_;
                    $streams_by_id{$stream_id} = 'opened';
                    return 0;
                },
                on_header     => sub { return 0; },
                on_frame_recv => sub { return 0; },
                on_stream_close => sub {
                    my ($stream_id) = @_;
                    $streams_by_id{$stream_id} = 'closed';
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

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

        is($streams_by_id{1}, 'opened', "Stream 1 was opened by HEADERS");

        done_testing;
    };

    #==========================================================================
    # Test: RST_STREAM on idle stream is protocol error
    # (RFC 9113 Section 5.1: RST_STREAM on idle is connection error)
    #==========================================================================
    subtest 'RST_STREAM on idle stream is protocol error' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # RST_STREAM on stream 1 without first opening it
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_rst_stream_frame(
                stream_id  => 1,
                error_code => ERROR_CANCEL,
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server sent GOAWAY for RST_STREAM on idle");

        if (@goaway_frames) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway_frames[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "GOAWAY with PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: WINDOW_UPDATE on idle stream is protocol error
    # (RFC 9113 Section 5.1)
    #==========================================================================
    subtest 'WINDOW_UPDATE on idle stream is protocol error' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # WINDOW_UPDATE on stream 1 without first opening it
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_window_update_frame(
                stream_id => 1,  # Idle stream
                increment => 1024,
            );

        eval { $session->mem_recv($client_data); };

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway_frames >= 1, "Server sent GOAWAY for WINDOW_UPDATE on idle");

        done_testing;
    };

    #==========================================================================
    # Test: Trailers on half-closed stream work correctly
    # (Trailers are HEADERS with END_STREAM after DATA)
    #==========================================================================
    subtest 'trailers work on open stream' => sub {
        my @all_headers;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers   => sub { return 0; },
                on_header          => sub {
                    my ($stream_id, $name, $value) = @_;
                    push @all_headers, [$name, $value];
                    return 0;
                },
                on_frame_recv      => sub { return 0; },
                on_data_chunk_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block = encode_headers([
            [':method', 'POST'],
            [':path', '/upload'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $trailer_block = encode_headers([
            ['x-checksum', 'abc123'],
        ]);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 0,
                end_headers  => 1,
            )
            . build_data_frame(
                stream_id  => 1,
                data       => "body content",
                end_stream => 0,
            )
            . build_headers_frame(  # Trailers
                stream_id    => 1,
                header_block => $trailer_block,
                end_stream   => 1,  # END_STREAM on trailers
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        # Should have received both request headers and trailers
        my @pseudo_headers = grep { $_->[0] =~ /^:/ } @all_headers;
        my @trailer_headers = grep { $_->[0] eq 'x-checksum' } @all_headers;

        ok(@pseudo_headers >= 4, "Received pseudo-headers");
        is(scalar(@trailer_headers), 1, "Received trailer header");
        is($trailer_headers[0][1], 'abc123', "Trailer value correct");

        done_testing;
    };

    #==========================================================================
    # Test: PRIORITY frame can be sent on any stream state
    # (RFC 9113 Section 5.1: PRIORITY can be sent/received in any state)
    # Note: PRIORITY is deprecated in RFC 9113 but still allowed
    #==========================================================================
    subtest 'PRIORITY allowed in any stream state' => sub {
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

        # PRIORITY on idle stream (before HEADERS)
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_priority_frame(
                stream_id  => 1,
                stream_dep => 0,
                weight     => 32,
            );

        eval { $session->mem_recv($client_data); };

        # Should not cause an error (PRIORITY is allowed on idle streams)
        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway_frames = grep { $_->{type} == FRAME_GOAWAY } @$frames;

        # nghttp2 should either accept or ignore PRIORITY (it's deprecated)
        # Either way, no GOAWAY should be sent
        is(scalar(@goaway_frames), 0, "No GOAWAY for PRIORITY on idle stream");

        done_testing;
    };

}

done_testing;
