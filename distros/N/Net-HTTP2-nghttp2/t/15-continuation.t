#!/usr/bin/env perl
# Tests ported from python-hyper/h2 test_complex_logic.py
# https://github.com/python-hyper/h2
#
# These tests verify CONTINUATION frame handling as per RFC 9113 Section 6.10

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
    # Test: Basic CONTINUATION frame handling
    # (test_continuation_frame_basic from python-hyper/h2)
    # Headers can be split across HEADERS + CONTINUATION frames
    #==========================================================================
    subtest 'basic CONTINUATION frame handling' => sub {
        my %headers_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    $headers_received{$name} = $value;
                    return 0;
                },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Encode headers and split into chunks
        my $header_block = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
            ['x-custom', 'value'],
        ]);

        # Split header block into two parts
        my $midpoint = int(length($header_block) / 2);
        my $first_part = substr($header_block, 0, $midpoint);
        my $second_part = substr($header_block, $midpoint);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $first_part,
                end_stream   => 1,
                end_headers  => 0,  # More headers coming
            )
            . build_continuation_frame(
                stream_id    => 1,
                header_block => $second_part,
                end_headers  => 1,  # End of headers
            );

        $session->mem_recv($client_data);

        is($headers_received{':method'}, 'GET', 'Method received via CONTINUATION');
        is($headers_received{':path'}, '/', 'Path received via CONTINUATION');
        is($headers_received{'x-custom'}, 'value', 'Custom header received via CONTINUATION');

        done_testing;
    };

    #==========================================================================
    # Test: Multiple CONTINUATION frames
    # Headers split across HEADERS + multiple CONTINUATIONs
    # Note: We encode headers separately to avoid splitting mid-encoding
    #==========================================================================
    subtest 'multiple CONTINUATION frames' => sub {
        my %headers_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    $headers_received{$name} = $value;
                    return 0;
                },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Encode header groups separately to ensure clean splits
        my $part1 = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
        ]);
        my $part2 = encode_headers([
            [':scheme', 'https'],
        ]);
        my $part3 = encode_headers([
            [':authority', 'example.com'],
        ]);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $part1,
                end_stream   => 1,
                end_headers  => 0,
            )
            . build_continuation_frame(
                stream_id    => 1,
                header_block => $part2,
                end_headers  => 0,
            )
            . build_continuation_frame(
                stream_id    => 1,
                header_block => $part3,
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        is($headers_received{':method'}, 'GET', 'Method received');
        is($headers_received{':path'}, '/', 'Path received');
        is($headers_received{':authority'}, 'example.com', 'Authority received');

        done_testing;
    };

    #==========================================================================
    # Test: CONTINUATION cannot interleave with HEADERS from another stream
    # (test_continuation_cannot_interleave_headers from python-hyper/h2)
    #==========================================================================
    subtest 'CONTINUATION cannot interleave with other HEADERS' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        my $header_block1 = encode_headers([
            [':method', 'GET'],
            [':path', '/'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        my $header_block2 = encode_headers([
            [':method', 'POST'],
            [':path', '/other'],
            [':scheme', 'https'],
            [':authority', 'localhost'],
        ]);

        # Start headers on stream 1, then try to send headers on stream 3
        # before completing stream 1's header block
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block1,
                end_stream   => 1,
                end_headers  => 0,  # More headers expected
            )
            . build_headers_frame(  # This interrupts stream 1's headers!
                stream_id    => 3,
                header_block => $header_block2,
                end_stream   => 1,
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway >= 1, "Server sent GOAWAY for interleaved HEADERS");

        if (@goaway) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "Error is PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: CONTINUATION cannot interleave with DATA
    # (test_continuation_cannot_interleave_data from python-hyper/h2)
    #==========================================================================
    subtest 'CONTINUATION cannot interleave with DATA' => sub {
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

        my $midpoint = int(length($header_block) / 2);

        # Start headers, then send DATA before CONTINUATION
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => substr($header_block, 0, $midpoint),
                end_stream   => 0,
                end_headers  => 0,  # More headers expected
            )
            . build_data_frame(  # This interrupts the header block!
                stream_id  => 1,
                data       => "invalid",
                end_stream => 0,
            );

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway >= 1, "Server sent GOAWAY for DATA during header block");

        if (@goaway) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "Error is PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: CONTINUATION cannot interleave with unknown frame types
    # (test_continuation_cannot_interleave_unknown_frame from python-hyper/h2)
    #==========================================================================
    subtest 'CONTINUATION cannot interleave with unknown frame' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
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

        my $midpoint = int(length($header_block) / 2);

        # Start headers, then send unknown frame before CONTINUATION
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => substr($header_block, 0, $midpoint),
                end_stream   => 1,
                end_headers  => 0,
            )
            . build_unknown_frame(  # Unknown frame type interrupts!
                type      => 0x58,  # Type 88 (unknown)
                stream_id => 1,
                payload   => "unknown",
            );

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway >= 1, "Server sent GOAWAY for unknown frame during header block");

        done_testing;
    };

    #==========================================================================
    # Test: CONTINUATION must have same stream ID
    #==========================================================================
    subtest 'CONTINUATION must match stream ID' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
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

        my $midpoint = int(length($header_block) / 2);

        # CONTINUATION on different stream ID than HEADERS
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => substr($header_block, 0, $midpoint),
                end_stream   => 1,
                end_headers  => 0,
            )
            . build_continuation_frame(
                stream_id    => 3,  # Wrong stream ID!
                header_block => substr($header_block, $midpoint),
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway >= 1, "Server sent GOAWAY for mismatched stream ID");

        if (@goaway) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "Error is PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: CONTINUATION without preceding HEADERS is rejected
    #==========================================================================
    subtest 'CONTINUATION without HEADERS rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
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

        # Send CONTINUATION without preceding HEADERS
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_continuation_frame(  # No HEADERS before this!
                stream_id    => 1,
                header_block => $header_block,
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway >= 1, "Server sent GOAWAY for orphan CONTINUATION");

        if (@goaway) {
            my ($last_stream_id, $error_code) = unpack("N N", $goaway[0]->{payload});
            is($error_code, ERROR_PROTOCOL_ERROR, "Error is PROTOCOL_ERROR");
        }

        done_testing;
    };

    #==========================================================================
    # Test: Empty CONTINUATION is valid
    #==========================================================================
    subtest 'empty CONTINUATION is valid' => sub {
        my %headers_received;

        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    $headers_received{$name} = $value;
                    return 0;
                },
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

        # Send all headers in HEADERS, then empty CONTINUATION
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => $header_block,
                end_stream   => 1,
                end_headers  => 0,
            )
            . build_continuation_frame(
                stream_id    => 1,
                header_block => '',  # Empty
                end_headers  => 1,
            );

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        is(scalar @goaway, 0, 'No GOAWAY for empty CONTINUATION');
        is($headers_received{':method'}, 'GET', 'Headers received correctly');

        done_testing;
    };

    #==========================================================================
    # Test: PING during header block is rejected
    # Connection-level frames like PING should also be rejected
    #==========================================================================
    subtest 'PING during header block rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
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

        my $midpoint = int(length($header_block) / 2);

        # PING during incomplete header block
        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => substr($header_block, 0, $midpoint),
                end_stream   => 1,
                end_headers  => 0,
            )
            . build_ping_frame(opaque_data => "12345678");

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway >= 1, "Server sent GOAWAY for PING during header block");

        done_testing;
    };

    #==========================================================================
    # Test: WINDOW_UPDATE during header block is rejected
    #==========================================================================
    subtest 'WINDOW_UPDATE during header block rejected' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_server(
            callbacks => {
                on_begin_headers => sub { return 0; },
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

        my $midpoint = int(length($header_block) / 2);

        my $client_data = CLIENT_PREFACE
            . build_settings_frame()
            . build_headers_frame(
                stream_id    => 1,
                header_block => substr($header_block, 0, $midpoint),
                end_stream   => 1,
                end_headers  => 0,
            )
            . build_window_update_frame(
                stream_id => 0,
                increment => 1000,
            );

        $session->mem_recv($client_data);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @goaway = grep { $_->{type} == FRAME_GOAWAY } @$frames;
        ok(@goaway >= 1, "Server sent GOAWAY for WINDOW_UPDATE during header block");

        done_testing;
    };

}

done_testing;
