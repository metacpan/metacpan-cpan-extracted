use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2 qw(NGHTTP2_NO_ERROR);
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_DATA FRAME_HEADERS FLAG_END_STREAM);

sub pump_sessions {
    my ($client, $server) = @_;

    for my $round (1 .. 100) {
        my $moved = 0;

        my $client_bytes = $client->mem_send;
        if (defined($client_bytes) && length($client_bytes)) {
            $server->mem_recv($client_bytes);
            $moved = 1;
        }

        my $server_bytes = $server->mem_send;
        if (defined($server_bytes) && length($server_bytes)) {
            $client->mem_recv($server_bytes);
            $moved = 1;
        }

        return unless $moved;
    }

    die "session pump did not become idle";
}

# A connected client and server with one request open. The client records
# every header block it receives, the DATA it receives and how its stream
# closed.
sub new_pair {
    my (%record) = (blocks => [], body => '', data_frames => [], closed => []);
    my (@current, $server_stream_id);

    my $server = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub { return 0 },
            on_header        => sub { return 0 },
            on_frame_recv    => sub {
                my ($frame) = @_;
                if ($frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0) {
                    $server_stream_id = $frame->{stream_id};
                }
                return 0;
            },
        },
    );

    my $client = Net::HTTP2::nghttp2::Session->new_client(
        callbacks => {
            on_begin_headers => sub {
                @current = ();
                return 0;
            },
            on_header => sub {
                my (undef, $name, $value) = @_;
                push @current, [$name, $value];
                return 0;
            },
            on_frame_recv => sub {
                my ($frame) = @_;
                if ($frame->{type} == FRAME_HEADERS) {
                    push @{ $record{blocks} }, {
                        flags   => $frame->{flags},
                        headers => [map { [@$_] } @current],
                    };
                }
                push @{ $record{data_frames} }, {%$frame} if $frame->{type} == FRAME_DATA;
                return 0;
            },
            on_data_chunk_recv => sub {
                my (undef, $data) = @_;
                $record{body} .= $data;
                return 0;
            },
            on_stream_close => sub {
                push @{ $record{closed} }, [@_];
                return 0;
            },
        },
    );

    $client->send_connection_preface;
    $server->send_connection_preface;
    pump_sessions($client, $server);

    $client->submit_request(
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => '/early-hints',
    );
    pump_sessions($client, $server);

    die "server did not receive the request stream"
        unless defined $server_stream_id;

    return ($client, $server, $server_stream_id, \%record);
}

subtest 'a 1xx header block precedes the final response' => sub {
    my ($client, $server, $stream_id, $record) = new_pair();

    my $rv = $server->submit_headers(
        $stream_id,
        headers => [
            [':status', '103'],
            ['link', '</style.css>; rel=preload; as=style'],
        ],
    );
    is($rv, 0, 'nghttp2 accepted the header block');
    $server->submit_response($stream_id, status => 200, body => 'ok');
    pump_sessions($client, $server);

    is(scalar @{ $record->{blocks} }, 2, 'the client received two header blocks');
    is_deeply(
        $record->{blocks}[0]{headers},
        [[':status', '103'], ['link', '</style.css>; rel=preload; as=style']],
        'the informational block arrives first, in order',
    );
    ok(!($record->{blocks}[0]{flags} & FLAG_END_STREAM),
        'the informational block does not end the stream');
    is($record->{blocks}[1]{headers}[0][1], '200', 'the final response follows');
    is($record->{body}, 'ok', 'the final response body arrives');
    is_deeply(
        [map { $_->[1] } @{ $record->{closed} }],
        [NGHTTP2_NO_ERROR],
        'the stream closes normally',
    );
};

subtest 'end_stream ends the stream on the header block' => sub {
    my ($client, $server, $stream_id, $record) = new_pair();

    $server->submit_headers($stream_id, headers => [[':status', '204']], end_stream => 1);
    pump_sessions($client, $server);

    is(scalar @{ $record->{blocks} }, 1, 'one header block');
    ok($record->{blocks}[0]{flags} & FLAG_END_STREAM, 'it carries END_STREAM');
    is(scalar @{ $record->{data_frames} }, 0, 'no DATA follows');
    is(scalar @{ $record->{closed} }, 1, 'the stream closed');
};

subtest 'submit_headers validates the Perl header shape' => sub {
    my ($client, $server, $stream_id) = new_pair();
    my @cases = (
        [
            'non-array header list',
            sub { $server->submit_headers($stream_id, headers => {}) },
            qr/submit_headers: headers must be an array reference/,
        ],
        [
            'non-array pair',
            sub { $server->submit_headers($stream_id, headers => ['x']) },
            qr/submit_headers: header 0 must be a two-element array reference/,
        ],
        [
            'one-element pair',
            sub { $server->submit_headers($stream_id, headers => [['x']]) },
            qr/submit_headers: header 0 must be a two-element array reference/,
        ],
        [
            'undefined name',
            sub { $server->submit_headers($stream_id, headers => [[undef, 'v']]) },
            qr/submit_headers: header 0 name must be a defined non-reference scalar/,
        ],
        [
            'reference value',
            sub { $server->submit_headers($stream_id, headers => [['x', []]]) },
            qr/submit_headers: header 0 value must be a defined non-reference scalar/,
        ],
    );

    for my $case (@cases) {
        my ($label, $call, $pattern) = @$case;
        my $ok = eval {
            $call->();
            1;
        };
        ok(!$ok, "$label dies");
        like($@, $pattern, "$label reports the precise input error");
    }
};

subtest 'stream ID zero fails immediately' => sub {
    my ($client, $server) = new_pair();
    my $ok = eval {
        $server->submit_headers(0, headers => [[':status', '103']]);
        1;
    };

    ok(!$ok, 'invalid stream ID dies');
    like($@, qr/nghttp2_submit_headers failed:/, 'native error is reported');
};

done_testing;
