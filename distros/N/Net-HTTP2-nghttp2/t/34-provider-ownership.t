use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# A streaming response registers a data provider that nghttp2 reads the body
# from. The session owns that provider only once the submit succeeded: a submit
# that fails never copied the descriptor, so the provider must be released
# before the exception leaves, and a stream that already has one must be
# refused outright. Otherwise a second provider lands under the same stream id,
# where stream close frees only the first and the other is orphaned.

my @released;

{
    package Test::Provider::Guard;

    sub new {
        my ($class, $name) = @_;
        return bless { name => $name }, $class;
    }

    sub DESTROY {
        my ($self) = @_;
        push @released, $self->{name};
        return;
    }
}

sub request_args {
    my ($path) = @_;
    return (
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    );
}

# A pair whose server records its stream ids and whose client collects bodies.
sub connected_pair {
    my ($streams, $bodies) = @_;
    return new_session_pair(
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @$streams, $frame->{stream_id}
                    if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
                return 0;
            },
        },
        client_callbacks => {
            on_data_chunk_recv => sub {
                my ($stream_id, $data) = @_;
                $bodies->{$stream_id} .= $data;
                return 0;
            },
        },
    );
}

subtest 'a second streaming response on a live stream is refused and leaks nothing' => sub {
    @released = ();
    my (@streams, %bodies);
    my ($client, $server) = connected_pair(\@streams, \%bodies);

    my $client_stream = $client->submit_request(request_args('/first'));
    pump_sessions($client, $server);
    is(scalar @streams, 1, 'the server received the request');
    my $stream_id = $streams[0];

    my $sent = 0;
    $server->submit_response(
        $stream_id,
        status        => 200,
        body          => sub { return ('', 1) if $sent++; return ('first-body', 1) },
        callback_data => Test::Provider::Guard->new('first'),
    );

    my $ok = eval {
        $server->submit_response(
            $stream_id,
            status        => 200,
            body          => sub { return ('second-body', 1) },
            callback_data => Test::Provider::Guard->new('second'),
        );
        1;
    };
    my $error = $@;

    ok(!$ok, 'the second response on the same stream was refused');
    like($error, qr/\Qstream $stream_id already has a data provider\E/,
        'the refusal names the stream that already has one');
    is_deeply(\@released, ['second'],
        'the refused response released its callback_data and left the live one held');

    pump_sessions($client, $server);
    is($bodies{$client_stream}, 'first-body',
        'the surviving provider still produced the first response body');

    undef $server;
    is_deeply([sort @released], ['first', 'second'],
        'every callback_data was released by the time the session was gone');
};

# nghttp2 copies the data provider descriptor only when the submit succeeds, so
# a non-zero return leaves the provider ours to free. Two returns are reachable
# from Perl: stream id 0 is NGHTTP2_ERR_INVALID_ARGUMENT, and a response on a
# client session is NGHTTP2_ERR_PROTO.
subtest 'a submit that fails releases the provider before croaking' => sub {
    @released = ();
    my (@streams, %bodies);
    my ($client, $server) = connected_pair(\@streams, \%bodies);

    $client->submit_request(request_args('/live'));
    pump_sessions($client, $server);

    my $ok = eval {
        $server->submit_response(
            0,
            status        => 200,
            body          => sub { return ('body', 1) },
            callback_data => Test::Provider::Guard->new('invalid-stream'),
        );
        1;
    };
    my $error = $@;
    ok(!$ok, 'a response on stream 0 was refused by nghttp2');
    like($error, qr/\Qnghttp2_submit_response failed: \E/,
        'the croak carries the nghttp2 message');
    is_deeply(\@released, ['invalid-stream'],
        'the provider for the failed submit was released, not orphaned');

    @released = ();
    $ok = eval {
        $client->submit_response(
            1,
            status        => 200,
            body          => sub { return ('body', 1) },
            callback_data => Test::Provider::Guard->new('client-session'),
        );
        1;
    };
    $error = $@;
    ok(!$ok, 'a response submitted on a client session was refused by nghttp2');
    like($error, qr/\Qnghttp2_submit_response failed: \E/,
        'the croak carries the nghttp2 message');
    is_deeply(\@released, ['client-session'],
        'the provider for the failed submit was released, not orphaned');
};

subtest 'a streaming response followed by a second request on a new stream is unchanged' => sub {
    @released = ();
    my (@streams, %bodies);
    my ($client, $server) = connected_pair(\@streams, \%bodies);

    my $first_stream = $client->submit_request(request_args('/one'));
    pump_sessions($client, $server);

    my $sent = 0;
    $server->submit_response(
        $streams[0],
        status        => 200,
        body          => sub { return ('', 1) if $sent++; return ('one-body', 1) },
        callback_data => Test::Provider::Guard->new('one'),
    );
    pump_sessions($client, $server);
    is($bodies{$first_stream}, 'one-body', 'the first streaming response arrived');

    my $second_stream = $client->submit_request(request_args('/two'));
    pump_sessions($client, $server);
    is(scalar @streams, 2, 'the server received the second request');

    my $sent_again = 0;
    $server->submit_response(
        $streams[1],
        status        => 200,
        body          => sub { return ('', 1) if $sent_again++; return ('two-body', 1) },
        callback_data => Test::Provider::Guard->new('two'),
    );
    pump_sessions($client, $server);
    is($bodies{$second_stream}, 'two-body', 'the second streaming response arrived');

    is_deeply([sort @released], ['one', 'two'],
        'both providers were released when their streams closed');
};

# A trailer does not register a provider, so the one-provider-per-stream rule
# must not disturb the streaming-plus-trailer path.
subtest 'a streaming response still accepts a trailer' => sub {
    @released = ();
    my (@streams, %bodies);
    my (%trailers, $client_stream);
    my ($client, $server) = new_session_pair(
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @streams, $frame->{stream_id}
                    if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
                return 0;
            },
        },
        client_callbacks => {
            on_data_chunk_recv => sub {
                my ($stream_id, $data) = @_;
                $bodies{$stream_id} .= $data;
                return 0;
            },
            on_header => sub {
                my ($stream_id, $name, $value) = @_;
                $trailers{$name} = $value if $name eq 'x-checksum';
                return 0;
            },
        },
    );

    $client_stream = $client->submit_request(request_args('/trailered'));
    pump_sessions($client, $server);

    my $sent = 0;
    $server->submit_response(
        $streams[0],
        status        => 200,
        body          => sub { return (undef) if $sent++; return ('trailered-body', 1, 1) },
        callback_data => Test::Provider::Guard->new('trailered'),
    );
    pump_sessions($client, $server);

    $server->submit_trailer($streams[0], headers => [['x-checksum', 'abc']]);
    pump_sessions($client, $server);

    is($bodies{$client_stream}, 'trailered-body', 'the body arrived');
    is($trailers{'x-checksum'}, 'abc', 'the trailer arrived after the body');
    is_deeply(\@released, ['trailered'], 'the provider was released when the stream closed');
};

done_testing;
