use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2;
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# A request whose body the client leaves open, so each half of the stream can
# be closed independently and queried from the server.
sub open_request_pair {
    my ($path) = @_;
    return new_session_pair(
        request => {
            method    => 'POST',
            scheme    => 'https',
            authority => 'example.test',
            path      => $path,
            body      => sub { return undef },
        },
    );
}

subtest 'remote_close follows the peer half of the stream' => sub {
    my ($client, $server, $client_stream_id, $stream_id) =
        open_request_pair('/remote');

    is($server->get_stream_remote_close($stream_id), 0,
        'the request half is open while the client can still send');
    is($server->get_stream_local_close($stream_id), 0,
        'the response half is open before the server answers');

    $client->submit_data($client_stream_id, '', 1);
    pump_sessions($client, $server);

    is($server->get_stream_remote_close($stream_id), 1,
        'the request half is closed after the client END_STREAM');
    is($server->get_stream_local_close($stream_id), 0,
        'the response half is still open');
};

subtest 'local_close follows the response half of the stream' => sub {
    my ($client, $server, undef, $stream_id) = open_request_pair('/local');

    is($server->get_stream_local_close($stream_id), 0,
        'the response half is open before the response ends');

    $server->submit_response($stream_id, status => 200, body => 'done');
    pump_sessions($client, $server);

    is($server->get_stream_local_close($stream_id), 1,
        'the response half is closed once the response ends');
    is($server->get_stream_remote_close($stream_id), 0,
        'the request half is still open');
};

subtest 'an unknown stream id has no answer' => sub {
    my ($client, $server, undef, $stream_id) = open_request_pair('/unknown');

    my $unknown = $stream_id + 4;
    is($server->get_stream_remote_close($unknown), undef,
        'remote_close is undef for an unknown stream');
    is($server->get_stream_local_close($unknown), undef,
        'local_close is undef for an unknown stream');

    is($client->get_stream_remote_close(0), undef,
        'the connection stream is not a stream');
    is($client->get_stream_local_close(0), undef,
        'the connection stream has no local half');
};

done_testing;
