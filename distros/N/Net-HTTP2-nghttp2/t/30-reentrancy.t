use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# mem_send and mem_recv drive the flush that runs the callbacks. Re-entering
# either one from inside a callback re-serializes the frame that is still being
# processed, which recurses until the C stack is gone. The session refuses the
# reentry instead.

sub request_args {
    my ($path) = @_;
    return {
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    };
}

subtest 'mem_send from inside on_frame_send croaks' => sub {
    my $server;
    my @errors;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my ($client, $session, undef, $stream_id) = new_session_pair(
        server_callbacks => {
            on_frame_send => sub {
                my ($frame) = @_;
                return 0 unless $frame->{stream_id} > 0;
                eval { $server->mem_send; 1 } or push @errors, $@;
                return 0;
            },
        },
        request => request_args('/reentrant-send'),
    );
    $server = $session;

    $server->submit_response($stream_id, status => 200, body => 'hello');
    pump_sessions($client, $server);

    ok(scalar @errors, 'the reentrant mem_send was refused');
    like($errors[0], qr/mem_send called from inside a session callback/,
        'the refusal names the reentry');
    is_deeply(\@warnings, [], 'the refusal did not also warn');
};

subtest 'mem_recv from inside on_frame_recv croaks' => sub {
    my $server;
    my @errors;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my ($client, $session) = new_session_pair(
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                return 0 unless $frame->{stream_id} > 0;
                eval { $server->mem_recv(''); 1 } or push @errors, $@;
                return 0;
            },
        },
    );
    $server = $session;

    $client->submit_request(%{ request_args('/reentrant-recv') });
    pump_sessions($client, $server);

    ok(scalar @errors, 'the reentrant mem_recv was refused');
    like($errors[0], qr/mem_recv called from inside a session callback/,
        'the refusal names the reentry');
    is_deeply(\@warnings, [], 'the refusal did not also warn');
};

subtest 'the session still works once the croak is caught' => sub {
    my $server;
    my $refusals = 0;
    my $body = '';
    my @server_streams;

    my ($client, $session) = new_session_pair(
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @server_streams, $frame->{stream_id}
                    if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
                return 0;
            },
            on_frame_send => sub {
                my ($frame) = @_;
                return 0 unless $frame->{stream_id} > 0;
                $refusals++ unless eval { $server->mem_send; 1 };
                return 0;
            },
        },
        client_callbacks => {
            on_data_chunk_recv => sub {
                my (undef, $data) = @_;
                $body .= $data;
                return 0;
            },
        },
    );
    $server = $session;

    $client->submit_request(%{ request_args('/still-works') });
    pump_sessions($client, $server);
    $server->submit_response($server_streams[0], status => 200, body => 'alive');
    pump_sessions($client, $server);

    ok($refusals, 'the callback saw at least one refusal');
    is($body, 'alive', 'the response was delivered anyway');

    # A second stream on the same session still completes.
    $body = '';
    $client->submit_request(%{ request_args('/again') });
    pump_sessions($client, $server);
    $server->submit_response($server_streams[-1], status => 200, body => 'again');
    pump_sessions($client, $server);
    is($body, 'again', 'a later stream on the same session still completes');
};

done_testing;
