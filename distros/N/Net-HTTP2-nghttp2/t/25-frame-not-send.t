use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(NGHTTP2_CANCEL NGHTTP2_ERR_STREAM_CLOSING);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS FLAG_END_STREAM);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# A response body far larger than the window the client advertises, so output
# is still queued when the stream is reset.
use constant PEER_WINDOW => 1024;
use constant BODY        => 'x' x (PEER_WINDOW * 16);

sub request_args {
    my ($path) = @_;
    return {
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    };
}

subtest 'a queued response HEADERS discarded by a reset is reported' => sub {
    my (@not_sent, $received);
    my ($client, $server, undef, $stream_id) = new_session_pair(
        client_settings  => { initial_window_size => PEER_WINDOW },
        client_callbacks => {
            on_data_chunk_recv => sub {
                my (undef, $data) = @_;
                $received += length $data;
                return 0;
            },
        },
        server_callbacks => {
            on_frame_not_send => sub {
                my ($frame, $lib_error_code) = @_;
                push @not_sent, { frame => {%$frame}, error => $lib_error_code };
                return 0;
            },
        },
        request => request_args('/discarded'),
    );

    $server->submit_response($stream_id, status => 200, body => BODY);
    $server->submit_rst_stream($stream_id, NGHTTP2_CANCEL);
    pump_sessions($client, $server);

    is(scalar @not_sent, 1, 'one discarded frame was reported');
    is($not_sent[0]{frame}{type}, FRAME_HEADERS,
        'the discarded frame is the response HEADERS');
    is($not_sent[0]{frame}{stream_id}, $stream_id,
        'the report names the reset stream');
    is($not_sent[0]{error}, NGHTTP2_ERR_STREAM_CLOSING,
        'the reset is reported as NGHTTP2_ERR_STREAM_CLOSING');
    ok(!$received, 'no response body reached the peer');
};

subtest 'a queued trailing HEADERS discarded by a reset is reported' => sub {
    my @not_sent;
    my $called = 0;
    my ($client, $server, undef, $stream_id) = new_session_pair(
        client_settings  => { initial_window_size => PEER_WINDOW },
        server_callbacks => {
            on_frame_not_send => sub {
                my ($frame, $lib_error_code) = @_;
                push @not_sent, { frame => {%$frame}, error => $lib_error_code };
                return 0;
            },
        },
        request => request_args('/discarded-trailers'),
    );

    $server->submit_response(
        $stream_id,
        status => 200,
        body   => sub {
            return undef if $called++;
            return (BODY, 1, 1);
        },
    );
    pump_sessions($client, $server);

    $server->submit_trailer($stream_id, headers => [['x-checksum', 'abc']]);
    $server->submit_rst_stream($stream_id, NGHTTP2_CANCEL);
    pump_sessions($client, $server);

    is(scalar @not_sent, 1, 'one discarded frame was reported');
    is($not_sent[0]{frame}{type}, FRAME_HEADERS,
        'the discarded frame is the trailing HEADERS');
    ok($not_sent[0]{frame}{flags} & FLAG_END_STREAM,
        'the discarded block was the one that would have ended the stream');
    is($not_sent[0]{error}, NGHTTP2_ERR_STREAM_CLOSING,
        'the reset is reported as NGHTTP2_ERR_STREAM_CLOSING');
};

# nghttp2 documents this callback as covering non-DATA frames only. Pin that,
# so callers do not read silence about a discarded DATA frame as delivery.
subtest 'a discarded DATA frame is not reported' => sub {
    my (@not_sent, @closed);
    my $received = 0;
    my ($client, $server, $client_stream_id, $stream_id) = new_session_pair(
        client_settings  => { initial_window_size => PEER_WINDOW },
        client_callbacks => {
            on_data_chunk_recv => sub {
                my (undef, $data) = @_;
                $received += length $data;
                return 0;
            },
            on_stream_close => sub {
                push @closed, [@_];
                return 0;
            },
        },
        server_callbacks => {
            on_frame_not_send => sub {
                my ($frame, $lib_error_code) = @_;
                push @not_sent, { frame => {%$frame}, error => $lib_error_code };
                return 0;
            },
        },
        request => request_args('/pending-data'),
    );

    $server->submit_response($stream_id, status => 200, body => BODY);
    pump_sessions($client, $server);

    is($received, PEER_WINDOW, 'the peer window bounded what was delivered');

    $server->submit_rst_stream($stream_id, NGHTTP2_CANCEL);
    pump_sessions($client, $server);

    is($received, PEER_WINDOW, 'the rest of the body was discarded');
    is(scalar @closed, 1, 'the stream closed');
    is_deeply(\@not_sent, [], 'the discarded DATA produced no report');
};

done_testing;
