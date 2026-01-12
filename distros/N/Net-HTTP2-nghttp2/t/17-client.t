#!/usr/bin/env perl
# Tests ported from python-hyper/h2 test_basic_logic.py TestBasicClient
# https://github.com/python-hyper/h2
#
# These tests verify client-side HTTP/2 behavior

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(:all);
use Test::HTTP2::HPACK qw(encode_headers);

# Server preface: SETTINGS frame
sub SERVER_PREFACE {
    return build_settings_frame();
}

# Check if client-side methods are available
sub client_available {
    return Net::HTTP2::nghttp2::Session->can('_new_client_xs');
}

SKIP: {
    skip "nghttp2 not available", 1 unless Net::HTTP2::nghttp2->available;
    skip "client-side not implemented yet", 1 unless client_available();

    #==========================================================================
    # Test: Client sends connection preface
    # (test_begin_connection from python-hyper/h2)
    #==========================================================================
    subtest 'client sends connection preface' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        my $data = $session->mem_send();

        # Client preface starts with magic string
        like($data, qr/^PRI \* HTTP\/2\.0\r\n\r\nSM\r\n\r\n/,
             'Client preface starts with magic string');

        # After magic, should have SETTINGS frame
        my $after_magic = substr($data, length(CLIENT_PREFACE));
        my ($frames, $remaining) = parse_frames($after_magic);

        ok(@$frames >= 1, 'At least one frame after preface');
        is($frames->[0]{type}, FRAME_SETTINGS, 'First frame is SETTINGS');

        done_testing;
    };

    #==========================================================================
    # Test: Client can send request headers
    # (test_sending_headers from python-hyper/h2)
    #==========================================================================
    subtest 'client can send request headers' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();  # Clear preface

        # Receive server preface
        $session->mem_recv(SERVER_PREFACE());

        # Submit a request
        my $stream_id = $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );

        is($stream_id, 1, 'First client stream is 1');

        my $data = $session->mem_send();
        my ($frames, $remaining) = parse_frames($data);

        # Should have SETTINGS ACK and HEADERS
        my @headers_frames = grep { $_->{type} == FRAME_HEADERS } @$frames;
        ok(@headers_frames >= 1, 'Client sent HEADERS frame');
        is($headers_frames[0]{stream_id}, 1, 'HEADERS on stream 1');

        done_testing;
    };

    #==========================================================================
    # Test: Client can receive response
    # (test_receiving_a_response from python-hyper/h2)
    #==========================================================================
    subtest 'client can receive response' => sub {
        my %headers_received;
        my $stream_ended = 0;

        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    $headers_received{$name} = $value;
                    return 0;
                },
                on_frame_recv    => sub {
                    my ($frame) = @_;
                    $stream_ended = 1 if $frame->{type} == FRAME_HEADERS
                                      && ($frame->{flags} & FLAG_END_STREAM);
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();

        # Receive server preface
        $session->mem_recv(SERVER_PREFACE());

        # Submit request
        $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );
        $session->mem_send();

        # Server sends response
        my $response_headers = encode_headers([
            [':status', '200'],
            ['content-type', 'text/html'],
        ]);

        my $server_response = build_headers_frame(
            stream_id    => 1,
            header_block => $response_headers,
            end_stream   => 1,
            end_headers  => 1,
        );

        $session->mem_recv($server_response);

        is($headers_received{':status'}, '200', 'Received 200 status');
        is($headers_received{'content-type'}, 'text/html', 'Received content-type');
        ok($stream_ended, 'Stream ended');

        done_testing;
    };

    #==========================================================================
    # Test: Client receives response with body
    #==========================================================================
    subtest 'client receives response with body' => sub {
        my $body_received = '';

        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_begin_headers   => sub { return 0; },
                on_header          => sub { return 0; },
                on_frame_recv      => sub { return 0; },
                on_data_chunk_recv => sub {
                    my ($stream_id, $data, $flags) = @_;
                    $body_received .= $data;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );
        $session->mem_send();

        # Server response with headers + data
        my $response_headers = encode_headers([
            [':status', '200'],
            ['content-length', '13'],
        ]);

        my $server_response = build_headers_frame(
            stream_id    => 1,
            header_block => $response_headers,
            end_stream   => 0,
            end_headers  => 1,
        ) . build_data_frame(
            stream_id  => 1,
            data       => "Hello, World!",
            end_stream => 1,
        );

        $session->mem_recv($server_response);

        is($body_received, "Hello, World!", 'Received response body');

        done_testing;
    };

    #==========================================================================
    # Test: Client handles multiple concurrent streams
    #==========================================================================
    subtest 'client handles multiple concurrent streams' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        # Open multiple streams
        my $stream1 = $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/resource1'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );

        my $stream2 = $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/resource2'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );

        my $stream3 = $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/resource3'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );

        is($stream1, 1, 'First stream is 1');
        is($stream2, 3, 'Second stream is 3');
        is($stream3, 5, 'Third stream is 5');

        my $data = $session->mem_send();
        my ($frames, $remaining) = parse_frames($data);

        my @headers_frames = grep { $_->{type} == FRAME_HEADERS } @$frames;
        is(scalar @headers_frames, 3, 'Sent 3 HEADERS frames');

        done_testing;
    };

    #==========================================================================
    # Test: Client stream IDs are always odd
    #==========================================================================
    subtest 'client stream IDs are odd' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        for my $i (1..5) {
            my $stream_id = $session->submit_request(
                headers => [
                    [':method', 'GET'],
                    [':path', "/resource$i"],
                    [':scheme', 'https'],
                    [':authority', 'localhost'],
                ],
            );

            ok($stream_id % 2 == 1, "Stream $stream_id is odd");
        }

        done_testing;
    };

    #==========================================================================
    # Test: Client can send POST with body
    #==========================================================================
    subtest 'client can send POST with body' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        my $body = "key=value&foo=bar";

        my $stream_id = $session->submit_request(
            headers => [
                [':method', 'POST'],
                [':path', '/submit'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
                ['content-type', 'application/x-www-form-urlencoded'],
                ['content-length', length($body)],
            ],
            body => $body,
        );

        is($stream_id, 1, 'Stream ID is 1');

        my $data = $session->mem_send();
        my ($frames, $remaining) = parse_frames($data);

        my @headers = grep { $_->{type} == FRAME_HEADERS } @$frames;
        my @data_frames = grep { $_->{type} == FRAME_DATA } @$frames;

        ok(@headers >= 1, 'Sent HEADERS frame');
        ok(@data_frames >= 1, 'Sent DATA frame');

        done_testing;
    };

    #==========================================================================
    # Test: Client handles server GOAWAY
    #==========================================================================
    subtest 'client handles server GOAWAY' => sub {
        my $goaway_received = 0;

        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub {
                    my ($frame) = @_;
                    $goaway_received = 1 if $frame->{type} == FRAME_GOAWAY;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        # Server sends GOAWAY
        my $goaway = build_goaway_frame(
            last_stream_id => 0,
            error_code     => ERROR_NO_ERROR,
        );

        $session->mem_recv($goaway);

        ok($goaway_received, 'GOAWAY received');

        # Note: After GOAWAY, client may still have pending writes (e.g., SETTINGS ACK)
        # Just verify that subsequent requests won't be sent
        # We can flush any pending writes
        $session->mem_send();

        # After flushing, should have nothing more to write
        ok(!$session->want_write(), 'No more writes after GOAWAY and flush');

        done_testing;
    };

    #==========================================================================
    # Test: Client handles RST_STREAM
    #==========================================================================
    subtest 'client handles RST_STREAM' => sub {
        my $stream_closed = 0;
        my $error_code_received;

        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub { return 0; },
                on_frame_recv    => sub { return 0; },
                on_stream_close  => sub {
                    my ($stream_id, $error_code) = @_;
                    $stream_closed = $stream_id;
                    $error_code_received = $error_code;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );
        $session->mem_send();

        # Server resets the stream
        my $rst = build_rst_stream_frame(
            stream_id  => 1,
            error_code => ERROR_CANCEL,
        );

        $session->mem_recv($rst);

        is($stream_closed, 1, 'Stream 1 was closed');
        is($error_code_received, ERROR_CANCEL, 'Error code is CANCEL');

        done_testing;
    };

    #==========================================================================
    # Test: Client handles PING
    #==========================================================================
    subtest 'client handles PING and sends ACK' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        # Server sends PING
        my $ping = build_ping_frame(opaque_data => "12345678");

        $session->mem_recv($ping);

        my $response = $session->mem_send();
        my ($frames, $remaining) = parse_frames($response);

        my @ping_acks = grep {
            $_->{type} == FRAME_PING && ($_->{flags} & FLAG_ACK)
        } @$frames;

        ok(@ping_acks >= 1, 'Client sent PING ACK');
        is($ping_acks[0]{payload}, "12345678", 'PING ACK has same opaque data');

        done_testing;
    };

    #==========================================================================
    # Test: Client receives trailers
    # (test_can_receive_trailers from python-hyper/h2)
    #==========================================================================
    subtest 'client receives trailers' => sub {
        my %headers;
        my %trailers;
        my $in_trailers = 0;

        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_begin_headers   => sub { return 0; },
                on_header          => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    if ($in_trailers) {
                        $trailers{$name} = $value;
                    } else {
                        $headers{$name} = $value;
                    }
                    return 0;
                },
                on_frame_recv      => sub { return 0; },
                on_data_chunk_recv => sub {
                    # After data, next headers are trailers
                    $in_trailers = 1;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );
        $session->mem_send();

        # Server sends response with trailers
        my $response_headers = encode_headers([
            [':status', '200'],
            ['content-type', 'text/plain'],
        ]);

        my $trailer_headers = encode_headers([
            ['x-checksum', 'abc123'],
            ['x-signature', 'xyz789'],
        ]);

        my $server_response = build_headers_frame(
            stream_id    => 1,
            header_block => $response_headers,
            end_stream   => 0,
            end_headers  => 1,
        ) . build_data_frame(
            stream_id  => 1,
            data       => "Response body",
            end_stream => 0,
        ) . build_headers_frame(
            stream_id    => 1,
            header_block => $trailer_headers,
            end_stream   => 1,
            end_headers  => 1,
        );

        $session->mem_recv($server_response);

        is($headers{':status'}, '200', 'Response status received');
        is($trailers{'x-checksum'}, 'abc123', 'Trailer x-checksum received');
        is($trailers{'x-signature'}, 'xyz789', 'Trailer x-signature received');

        done_testing;
    };

    #==========================================================================
    # Test: Client handles WINDOW_UPDATE from server
    #==========================================================================
    subtest 'client handles WINDOW_UPDATE' => sub {
        my @frames_received;

        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub {
                    my ($frame) = @_;
                    push @frames_received, $frame;
                    return 0;
                },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        # Server sends WINDOW_UPDATE
        my $window_update = build_window_update_frame(
            stream_id => 0,
            increment => 65535,
        );

        $session->mem_recv($window_update);

        my @wu = grep { $_->{type} == FRAME_WINDOW_UPDATE } @frames_received;
        ok(@wu >= 1, 'WINDOW_UPDATE received');

        done_testing;
    };

    #==========================================================================
    # Test: Client sends END_STREAM without body
    # (test_end_stream_without_data from python-hyper/h2)
    #==========================================================================
    subtest 'client sends END_STREAM without body' => sub {
        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_frame_recv => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        # GET request - no body, should have END_STREAM on HEADERS
        $session->submit_request(
            headers => [
                [':method', 'GET'],
                [':path', '/'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
            ],
        );

        my $data = $session->mem_send();
        my ($frames, $remaining) = parse_frames($data);

        my @headers = grep { $_->{type} == FRAME_HEADERS } @$frames;
        ok(@headers >= 1, 'HEADERS frame sent');
        ok($headers[0]{flags} & FLAG_END_STREAM, 'HEADERS has END_STREAM flag');

        done_testing;
    };

    #==========================================================================
    # Test: Client handles informational response (100 Continue)
    # (test_header_tuples_are_decoded_info_response from python-hyper/h2)
    #==========================================================================
    subtest 'client handles 100 Continue' => sub {
        my @statuses;

        my $session = Net::HTTP2::nghttp2::Session->new_client(
            callbacks => {
                on_begin_headers => sub { return 0; },
                on_header        => sub {
                    my ($stream_id, $name, $value, $flags) = @_;
                    push @statuses, $value if $name eq ':status';
                    return 0;
                },
                on_frame_recv    => sub { return 0; },
            },
        );

        $session->send_connection_preface();
        $session->mem_send();
        $session->mem_recv(SERVER_PREFACE());

        $session->submit_request(
            headers => [
                [':method', 'POST'],
                [':path', '/upload'],
                [':scheme', 'https'],
                [':authority', 'localhost'],
                ['expect', '100-continue'],
            ],
        );
        $session->mem_send();

        # Server sends 100 Continue, then 200 OK
        my $continue_headers = encode_headers([
            [':status', '100'],
        ]);

        my $ok_headers = encode_headers([
            [':status', '200'],
            ['content-length', '0'],
        ]);

        my $server_response = build_headers_frame(
            stream_id    => 1,
            header_block => $continue_headers,
            end_stream   => 0,
            end_headers  => 1,
        ) . build_headers_frame(
            stream_id    => 1,
            header_block => $ok_headers,
            end_stream   => 1,
            end_headers  => 1,
        );

        $session->mem_recv($server_response);

        is(scalar @statuses, 2, 'Received two status headers');
        is($statuses[0], '100', 'First status is 100');
        is($statuses[1], '200', 'Second status is 200');

        done_testing;
    };

}

done_testing;
