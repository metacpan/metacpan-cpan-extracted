use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(NGHTTP2_CANCEL NGHTTP2_NO_ERROR);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# A response submitted for a stream the peer has already reset is accepted by
# nghttp2 and discarded later, reported through on_frame_not_send. No
# on_stream_close is coming for that stream: it already fired. The provider the
# submit registered has to be released there, or the session holds it and its
# Perl callback_data until the session itself is gone -- one leak per reset, the
# Rapid Reset shape.
#
# nghttp2.h, nghttp2_error: NGHTTP2_ERR_STREAM_CLOSED = -510. The module does
# not export it.
use constant ERR_STREAM_CLOSED => -510;

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

subtest 'a response discarded for a closed stream releases its provider' => sub {
    @released = ();
    my (@not_sent, @closed, %bodies);
    my $server;

    my @streams;
    my ($client, $srv, $client_stream, $stream_id) = new_session_pair(
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @streams, $frame->{stream_id}
                    if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
                return 0;
            },
            on_frame_not_send => sub {
                my ($frame, $lib_error_code) = @_;
                push @not_sent, {
                    frame        => {%$frame},
                    error        => $lib_error_code,
                    remote_close => $server->get_stream_remote_close($frame->{stream_id}),
                };
                return 0;
            },
            on_stream_close => sub {
                push @closed, $_[0];
                return 0;
            },
        },
        client_callbacks => {
            on_data_chunk_recv => sub {
                my ($id, $data) = @_;
                $bodies{$id} .= $data;
                return 0;
            },
        },
        request => { request_args('/cancelled') },
    );
    $server = $srv;

    $client->submit_rst_stream($client_stream, NGHTTP2_CANCEL);
    pump_sessions($client, $server);

    is_deeply(\@closed, [$stream_id], 'the server saw the reset stream close');
    is($server->get_stream_remote_close($stream_id), undef,
        'nghttp2 no longer has the stream');

    my $produced = 0;
    is($server->submit_response(
        $stream_id,
        status        => 200,
        body          => sub { return (undef) if $produced++; return ('late-body', 1) },
        callback_data => Test::Provider::Guard->new('cancelled'),
    ), 0, 'nghttp2 accepted the response for the closed stream');

    is_deeply(\@released, [], 'the provider is held while the response is queued');

    pump_sessions($client, $server);

    is(scalar @not_sent, 1, 'one discarded frame was reported');
    is($not_sent[0]{frame}{type}, FRAME_HEADERS,
        'the discarded frame is the response HEADERS');
    is($not_sent[0]{frame}{stream_id}, $stream_id, 'the report names the closed stream');
    is($not_sent[0]{error}, ERR_STREAM_CLOSED,
        'the discard is reported as NGHTTP2_ERR_STREAM_CLOSED');
    is($not_sent[0]{remote_close}, undef,
        'the stream was already gone when the frame was discarded');

    is_deeply(\@released, ['cancelled'],
        'the discarded response released its callback_data while the session was alive');

    # The session is still usable: a fresh stream gets a normal response.
    my $next_client_stream = $client->submit_request(request_args('/after'));
    pump_sessions($client, $server);
    is(scalar @streams, 2, 'the server received the second request');
    my $next_stream = $streams[-1];

    my $sent = 0;
    $server->submit_response(
        $next_stream,
        status        => 200,
        body          => sub { return ('', 1) if $sent++; return ('after-body', 1) },
        callback_data => Test::Provider::Guard->new('after'),
    );
    pump_sessions($client, $server);

    is($bodies{$next_client_stream}, 'after-body',
        'a fresh stream on the same session still gets its response');
    is_deeply([sort @released], ['after', 'cancelled'],
        'both providers were released before the session was destroyed');

    undef $server;
    undef $srv;
    undef $client;
    is_deeply([sort @released], ['after', 'cancelled'],
        'session destruction had nothing left to release');
};

# The release must key on the stream being gone, not on the frame being
# discarded. A HEADERS refused while its stream is still open leaves a live
# response half that the provider is still feeding.
subtest 'a HEADERS refused on a live stream keeps the stream provider' => sub {
    @released = ();
    my (@not_sent, %bodies);
    my $server;

    my ($client, $srv, $client_stream, $stream_id) = new_session_pair(
        server_callbacks => {
            on_frame_not_send => sub {
                my ($frame, $lib_error_code) = @_;
                push @not_sent, {
                    frame        => {%$frame},
                    error        => $lib_error_code,
                    remote_close => $server->get_stream_remote_close($frame->{stream_id}),
                };
                return 0;
            },
        },
        client_callbacks => {
            on_data_chunk_recv => sub {
                my ($id, $data) = @_;
                $bodies{$id} .= $data;
                return 0;
            },
        },
        request => { request_args('/live') },
    );
    $server = $srv;

    # EOF with NO_END_STREAM: the body is complete but the stream stays open
    # for a trailer, so the provider is still registered.
    my $produced = 0;
    $server->submit_response(
        $stream_id,
        status        => 200,
        body          => sub { return (undef) if $produced++; return ('live-body', 1, 1) },
        callback_data => Test::Provider::Guard->new('live'),
    );
    pump_sessions($client, $server);
    is($bodies{$client_stream}, 'live-body', 'the body reached the peer');

    # A trailer block too large to serialize is discarded without touching the
    # stream, which stays open.
    $server->submit_trailer($stream_id, headers => [['x-big', 'y' x 200_000]]);
    pump_sessions($client, $server);

    is(scalar @not_sent, 1, 'the oversized trailer was reported as not sent');
    is($not_sent[0]{frame}{type}, FRAME_HEADERS, 'the discarded frame is a HEADERS');
    is($not_sent[0]{remote_close}, 1,
        'the stream still existed when the frame was discarded');
    is_deeply(\@released, [], 'the live stream kept its provider');

    my $refused = !eval {
        $server->submit_response(
            $stream_id,
            status        => 200,
            body          => sub { return ('second', 1) },
            callback_data => Test::Provider::Guard->new('second'),
        );
        1;
    };
    ok($refused, 'the stream still holds a provider, so a second one is refused');
    is_deeply(\@released, ['second'], 'only the refused provider was released');

    @released = ();
    $server->submit_rst_stream($stream_id, NGHTTP2_NO_ERROR);
    pump_sessions($client, $server);
    is_deeply(\@released, ['live'], 'closing the stream released its provider');
};

done_testing;
