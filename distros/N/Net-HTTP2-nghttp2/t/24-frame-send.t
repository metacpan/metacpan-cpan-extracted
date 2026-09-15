use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(
    NGHTTP2_NO_ERROR
    NGHTTP2_HCAT_RESPONSE NGHTTP2_HCAT_HEADERS
);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(
    FRAME_DATA FRAME_HEADERS FRAME_RST_STREAM FLAG_END_STREAM parse_frames
);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

sub request_args {
    my ($path) = @_;
    return {
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    };
}

subtest 'a plain response reports HEADERS then DATA with END_STREAM' => sub {
    my @sent;
    my ($client, $server, undef, $stream_id) = new_session_pair(
        server_callbacks => {
            on_frame_send => sub {
                my ($frame) = @_;
                push @sent, {%$frame} if $frame->{stream_id} > 0;
                return 0;
            },
        },
        request => request_args('/plain'),
    );

    $server->submit_response($stream_id, status => 200, body => 'hello');
    pump_sessions($client, $server);

    is(scalar @sent, 2, 'two stream frames were serialized');
    is($sent[0]{type}, FRAME_HEADERS, 'HEADERS is reported first');
    is($sent[0]{stream_id}, $stream_id, 'HEADERS carries the response stream id');
    is($sent[0]{headers_category}, NGHTTP2_HCAT_RESPONSE,
        'HEADERS reports the response category');
    ok(!($sent[0]{flags} & FLAG_END_STREAM), 'HEADERS does not end the stream');
    is($sent[1]{type}, FRAME_DATA, 'DATA is reported second');
    is($sent[1]{stream_id}, $stream_id, 'DATA carries the response stream id');
    is($sent[1]{length}, length('hello'), 'DATA reports the payload length');
    ok($sent[1]{flags} & FLAG_END_STREAM, 'the final DATA carries END_STREAM');
};

subtest 'a trailers-terminated response reports the trailing HEADERS' => sub {
    my @sent;
    my $called = 0;
    my ($client, $server, undef, $stream_id) = new_session_pair(
        server_callbacks => {
            on_frame_send => sub {
                my ($frame) = @_;
                push @sent, {%$frame} if $frame->{stream_id} > 0;
                return 0;
            },
        },
        request => request_args('/trailers'),
    );

    $server->submit_response(
        $stream_id,
        status => 200,
        body   => sub {
            if (!$called++) {
                $server->submit_trailer(
                    $stream_id,
                    headers => [['x-checksum', 'abc']],
                );
            }
            return ('body', 1, 1);
        },
    );
    pump_sessions($client, $server);

    is(scalar @sent, 3, 'three stream frames were serialized');
    is($sent[0]{type}, FRAME_HEADERS, 'response HEADERS is reported first');
    is($sent[1]{type}, FRAME_DATA, 'DATA is reported second');
    ok(!($sent[1]{flags} & FLAG_END_STREAM),
        'DATA reserves END_STREAM for the trailers');
    is($sent[2]{type}, FRAME_HEADERS, 'trailing HEADERS is reported last');
    is($sent[2]{headers_category}, NGHTTP2_HCAT_HEADERS,
        'the trailing block is a later HEADERS block');
    ok($sent[2]{flags} & FLAG_END_STREAM, 'the trailing HEADERS ends the stream');
};

subtest 'the callback is optional' => sub {
    my $body = '';
    my @closed;
    my ($client, $server, $client_stream_id, $stream_id) = new_session_pair(
        client_callbacks => {
            on_data_chunk_recv => sub {
                my (undef, $data) = @_;
                $body .= $data;
                return 0;
            },
            on_stream_close => sub {
                push @closed, [@_];
                return 0;
            },
        },
        request => request_args('/no-callback'),
    );

    $server->submit_response($stream_id, status => 200, body => 'quiet');
    pump_sessions($client, $server);

    is($body, 'quiet', 'a session without on_frame_send still responds');
    is_deeply(\@closed, [[$client_stream_id, NGHTTP2_NO_ERROR]],
        'the stream closes cleanly');
};

subtest 'rst_stream submitted from inside the callback follows END_STREAM' => sub {
    my (@sent, @wire, @client_frames);
    my ($client, $server, $stream_id, $reset_stream_id);

    my $on_frame_send = sub {
        my ($frame) = @_;
        return 0 unless $frame->{stream_id} > 0;
        push @sent, {%$frame};
        if ($frame->{flags} & FLAG_END_STREAM) {
            $reset_stream_id = $frame->{stream_id};
            $server->submit_rst_stream($frame->{stream_id}, NGHTTP2_NO_ERROR);
        }
        return 0;
    };

    ($client, $server, undef, $stream_id) = new_session_pair(
        server_callbacks => { on_frame_send => $on_frame_send },
        client_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @client_frames, {%$frame} if $frame->{stream_id} > 0;
                return 0;
            },
        },
        request => request_args('/reset-after-end'),
    );

    $server->submit_response($stream_id, status => 200, body => 'done');
    pump_sessions($client, $server, sub { push @wire, $_[0] });

    is($reset_stream_id, $stream_id, 'the END_STREAM frame identified the stream');

    my ($frames) = parse_frames(join '', @wire);
    my @stream_frames = grep { $_->{stream_id} == $stream_id } @$frames;

    is(scalar @stream_frames, 3, 'the wire carries three stream frames');
    is($stream_frames[1]{type}, FRAME_DATA, 'DATA precedes the reset');
    ok($stream_frames[1]{flags} & FLAG_END_STREAM, 'that DATA carries END_STREAM');
    is($stream_frames[2]{type}, FRAME_RST_STREAM, 'RST_STREAM follows END_STREAM');
    is(unpack('N', $stream_frames[2]{payload}), NGHTTP2_NO_ERROR,
        'the reset uses NO_ERROR');

    is_deeply(
        [map { $_->{type} } @client_frames],
        [FRAME_HEADERS, FRAME_DATA, FRAME_RST_STREAM],
        'the client sees the reset after the END_STREAM frame',
    );
};

done_testing;
