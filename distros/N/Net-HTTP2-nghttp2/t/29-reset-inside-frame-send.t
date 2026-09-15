use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(NGHTTP2_NO_ERROR);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_DATA FRAME_HEADERS FRAME_RST_STREAM);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# A streaming response whose data provider still has chunks pending when the
# server's on_frame_send resets the stream. nghttp2 closes the stream inside
# the same nghttp2_session_send that is serializing the DATA frame, so the
# provider must outlive the send that is still holding it.

my $ITERATIONS = 20;

sub request_args {
    my ($path) = @_;
    return {
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    };
}

sub run_scenario {
    my @server_request_streams;
    my @client_stream_frames;
    my %client_body;

    my $server;
    my $reset_stream;
    my $provider_calls   = 0;
    my $calls_at_close;

    my ($client, $session, undef, $stream_id) = new_session_pair(
        # A small per-stream window keeps the response DATA queued, so the
        # provider is still live when the reset arrives.
        client_settings  => { initial_window_size => 128 },
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @server_request_streams, $frame->{stream_id}
                    if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
                return 0;
            },
            on_frame_send => sub {
                my ($frame) = @_;
                return 0 unless $frame->{stream_id} > 0;
                if ($frame->{type} == FRAME_DATA && !defined $reset_stream) {
                    $reset_stream = $frame->{stream_id};
                    $server->submit_rst_stream($frame->{stream_id}, NGHTTP2_NO_ERROR);
                }
                return 0;
            },
            on_stream_close => sub {
                my ($closed_stream_id) = @_;
                $calls_at_close = $provider_calls
                    if defined $reset_stream && $closed_stream_id == $reset_stream;
                return 0;
            },
        },
        client_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @client_stream_frames, {%$frame} if $frame->{stream_id} > 0;
                return 0;
            },
            on_data_chunk_recv => sub {
                my ($chunk_stream_id, $data) = @_;
                $client_body{$chunk_stream_id} .= $data;
                return 0;
            },
        },
        request => request_args('/streaming'),
    );
    $server = $session;

    my $chunks_emitted = 0;
    $server->submit_response(
        $stream_id,
        status => 200,
        body   => sub {
            $provider_calls++;
            $chunks_emitted++;
            return ('x' x 64, $chunks_emitted >= 40 ? 1 : 0);
        },
    );
    pump_sessions($client, $server);

    my $calls_after_pump = $provider_calls;

    # The session must still serve a fresh stream once the reset settles.
    my $second_client_stream = $client->submit_request(%{ request_args('/second') });
    pump_sessions($client, $server);
    my $second_server_stream = $server_request_streams[-1];
    $server->submit_response($second_server_stream, status => 200, body => 'second');
    pump_sessions($client, $server);

    return {
        stream_id        => $stream_id,
        reset_stream     => $reset_stream,
        client_frames    => \@client_stream_frames,
        calls_at_close   => $calls_at_close,
        calls_after_pump => $calls_after_pump,
        second_body      => $client_body{$second_client_stream},
        request_streams  => \@server_request_streams,
    };
}

for my $iteration (1 .. $ITERATIONS) {
    subtest "iteration $iteration: reset from on_frame_send with a pending provider" => sub {
        my $result = run_scenario();

        is($result->{reset_stream}, $result->{stream_id},
            'the first DATA frame identified the stream to reset');

        ok(
            (grep { $_->{type} == FRAME_RST_STREAM
                        && $_->{stream_id} == $result->{stream_id} }
                 @{ $result->{client_frames} }),
            'the client received the RST_STREAM',
        );

        ok(defined $result->{calls_at_close}, 'the reset stream was closed');
        is($result->{calls_after_pump}, $result->{calls_at_close},
            'the data provider callback was not invoked after the stream closed');

        is(scalar @{ $result->{request_streams} }, 2,
            'the server received a second request');
        is($result->{second_body}, 'second',
            'the session still serves a stream after the reset');
    };
}

done_testing;
