use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);
use Test::HTTP2::Pair qw(new_session_pair pump_sessions);

# mem_send and mem_recv mark the session as busy so a callback cannot re-enter
# them. The binding reports a failed callback with warn(), which is outside the
# eval that traps the callback itself, so a $SIG{__WARN__} handler that throws
# unwinds straight out of the session call. The busy mark has to be restored on
# that unwind, or the session refuses every later call with a reentrancy error
# it invented.

sub request_args {
    my ($path) = @_;
    return {
        method    => 'GET',
        scheme    => 'https',
        authority => 'example.test',
        path      => $path,
    };
}

subtest 'an exception thrown from a warn handler leaves mem_send usable' => sub {
    my @server_streams;
    my @logged;
    local $SIG{__WARN__} = sub { push @logged, $_[0] };

    my ($client, $server) = new_session_pair(
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                push @server_streams, $frame->{stream_id}
                    if $frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0;
                return 0;
            },
            # An ordinary logging callback.
            on_frame_send => sub {
                my ($frame) = @_;
                warn "sent frame type $frame->{type}\n";
                return 0;
            },
        },
    );

    $client->submit_request(%{ request_args('/unwind') });
    pump_sessions($client, $server);
    is(scalar @server_streams, 1, 'the server received the request');

    $server->submit_response($server_streams[0], status => 200, body => 'hello');

    my $escaped;
    {
        # A logger that dies - a closed handle, a log-to-die policy.
        local $SIG{__WARN__} = sub { die "logger failed\n" };
        $escaped = $@ unless eval { $server->mem_send; 1 };
    }

    is($escaped, "logger failed\n", 'the logger exception escaped mem_send');
    ok(scalar @logged, 'the logging callback ran before the throwing handler');

    my $bytes = eval { $server->mem_send };
    my $error = $@;
    is($error, '', 'the next mem_send did not croak');
    unlike($error, qr/from inside a session callback/,
        'the session was not left marked as busy');
    ok(defined $bytes, 'the next mem_send returned a string');
};

subtest 'an exception thrown from a warn handler leaves mem_recv usable' => sub {
    my @logged;
    local $SIG{__WARN__} = sub { push @logged, $_[0] };

    my ($client, $server) = new_session_pair(
        server_callbacks => {
            on_frame_recv => sub {
                my ($frame) = @_;
                warn "received frame type $frame->{type}\n";
                return 0;
            },
        },
    );

    $client->submit_request(%{ request_args('/unwind-recv') });
    my $wire = $client->mem_send;
    ok(length $wire, 'the client produced request bytes');

    my $escaped;
    {
        local $SIG{__WARN__} = sub { die "logger failed\n" };
        $escaped = $@ unless eval { $server->mem_recv($wire); 1 };
    }

    is($escaped, "logger failed\n", 'the logger exception escaped mem_recv');
    ok(scalar @logged, 'the logging callback ran before the throwing handler');

    my $consumed = eval { $server->mem_recv('') };
    my $error = $@;
    is($error, '', 'the next mem_recv did not croak');
    ok(defined $consumed, 'the next mem_recv returned a count');
};

done_testing;
