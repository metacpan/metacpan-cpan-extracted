use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Socket qw(PF_UNIX SOCK_STREAM);

BEGIN {
    unless ( eval { require POE; require JSON::MaybeXS; 1 } ) {
        plan skip_all =>
            'POE and JSON::MaybeXS are required for the client test';
    }
}

plan skip_all => 'Unix domain sockets are unavailable'
    unless eval { socket( my $s, PF_UNIX, SOCK_STREAM, 0 ) };

use POE;
use POE::Component::Server::JSONUnix;
use POE::Component::Server::JSONUnix::Client;

my $dir      = tempdir( CLEANUP => 1 );
my $sock_a   = "$dir/plain.sock";     # no auth requirement
my $sock_b   = "$dir/auth.sock";      # auth_required
my $auth_tmp = "$dir/auth_files";
mkdir $auth_tmp or die "mkdir: $!";

my $my_uid      = $>;
my $my_username = ( getpwuid($my_uid) )[0] // '';

# ---------------------------------------------------------------------------
# Servers. Both live in this process; everything below is one kernel run.
# ---------------------------------------------------------------------------

# Answers 'slow' requests after a delay, from outside the server's handler --
# exercises the client's timeout-then-late-response path.
POE::Session->create(
    inline_states => {
        _start       => sub { $_[KERNEL]->alias_set('slow_responder') },
        answer_later => sub {
            my ( $kernel, $ctx, $delay, $value ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
            $kernel->delay_set( answer => $delay, $ctx, $value );
        },
        answer   => sub { my ( $ctx, $value ) = @_[ ARG0, ARG1 ]; $ctx->respond_result($value) },
        shutdown => sub {
            $_[KERNEL]->alias_remove('slow_responder');
            $_[KERNEL]->alarm_remove_all;
        },
    },
);

my $server_a = POE::Component::Server::JSONUnix->spawn(
    socket_path => $sock_a,
    alias       => 'server_a',
    commands    => {
        echo => sub {
            my ( $s, $req, $ctx ) = @_;
            return { args => $req->{args} };
        },
        blackhole => sub { return },    # never answers
        slow      => sub {
            my ( $s, $req, $ctx ) = @_;
            $poe_kernel->post( slow_responder => answer_later => $ctx, 0.8, { slow => 1 } );
            return;
        },
    },
);

my $server_b = POE::Component::Server::JSONUnix->spawn(
    socket_path   => $sock_b,
    alias         => 'server_b',
    auth_temp_dir => $auth_tmp,
    auth_required => 1,
    commands      => {
        whoami => sub {
            my ( $s, $req, $ctx ) = @_;
            return { uid => $ctx->uid, username => $ctx->username };
        },
    },
);

# ---------------------------------------------------------------------------
# Track bookkeeping: each independent test track calls track_done() when it
# finishes; the finale runs once all of them have.
# ---------------------------------------------------------------------------
my $tracks_remaining = 6;
my %disconnects;    # finale: which clients have seen on_disconnect

sub track_done {
    $tracks_remaining--;
    finale() if $tracks_remaining == 0;
}

# Watchdog: fail loudly rather than hang if some callback never fires.
POE::Session->create(
    inline_states => {
        _start   => sub { $_[KERNEL]->alias_set('watchdog'); $_[KERNEL]->delay( timeout => 30 ) },
        timeout  => sub {
            fail("test timed out with $tracks_remaining track(s) unfinished");
            $_[KERNEL]->stop;
        },
        all_done => sub {
            $_[KERNEL]->delay('timeout');    # clear the alarm
            $_[KERNEL]->alias_remove('watchdog');
        },
    },
);

# ---------------------------------------------------------------------------
# Track 1: callback-style requests against server A.
# Connect, ping, correlation of concurrent requests, context passthrough,
# unknown commands, timeouts, and late responses via on_notice.
# ---------------------------------------------------------------------------
my $client1;
my $slow_request_id;

$client1 = POE::Component::Server::JSONUnix::Client->spawn(
    socket_path => $sock_a,
    alias       => 'client1',
    on_connect  => sub {
        my ($c) = @_;
        pass('client1: on_connect fired');
        ok( $c->connected, 'client1: connected() true inside on_connect' );

        # Fire-and-forget: no callback, no event. Just must not blow up.
        $c->call( command => 'ping' );

        my $ping_id;
        $ping_id = $c->call(
            command  => 'ping',
            callback => sub {
                my ($response) = @_;
                is( $response->{status},       'ok',     'client1: ping ok' );
                is( $response->{id},           $ping_id, 'client1: response id matches the id call() returned' );
                is( $response->{result}{pong}, 1,        'client1: pong payload' );
                client1_concurrent();
            },
        );
    },
    on_notice => sub {
        my ( $c, $response ) = @_;
        is( $response->{id}, $slow_request_id, 'client1: late response routed to on_notice with its id' );
        is( $response->{status}, 'ok', 'client1: late response still carries the real result' );
        is_deeply( $response->{result}, { slow => 1 }, 'client1: late response payload intact' );
        track_done();    # keep client1 connected for the finale
    },
    on_disconnect => sub {
        my ( $c, $reason ) = @_;
        like( $reason, qr/closed/, 'client1: on_disconnect reason mentions the close' );
        $disconnects{client1} = 1;
        finale_step2();
    },
);

# Three concurrent requests; each response must land in its own callback.
sub client1_concurrent {
    my $outstanding = 3;
    for my $tag (qw(alpha beta gamma)) {
        $client1->call(
            command  => 'echo',
            args     => { tag => $tag },
            context  => "ctx-$tag",
            callback => sub {
                my ( $response, $context ) = @_;
                is( $response->{status}, 'ok', "client1: echo($tag) ok" );
                is_deeply(
                    $response->{result}{args},
                    { tag => $tag },
                    "client1: echo($tag) correlated to the right callback"
                );
                is( $context, "ctx-$tag", "client1: echo($tag) context passed through" );
                $outstanding--;
                client1_timeouts() if $outstanding == 0;
            },
        );
    }
}

sub client1_timeouts {
    $client1->call(
        command  => 'no_such_command',
        callback => sub {
            my ($response) = @_;
            is( $response->{status}, 'error', 'client1: unknown command errors' );
            like( $response->{error}, qr/unknown command/, 'client1: unknown-command message' );
        },
    );

    $client1->call(
        command  => 'blackhole',
        timeout  => 0.3,
        callback => sub {
            my ($response) = @_;
            is( $response->{status}, 'error', 'client1: unanswered request times out' );
            like( $response->{error}, qr/timed out/, 'client1: timeout message' );
        },
    );

    # Server answers after 0.8s but the local timeout fires at 0.3s: the
    # callback must get the timeout, then on_notice the late real response.
    $slow_request_id = $client1->call(
        command  => 'slow',
        timeout  => 0.3,
        callback => sub {
            my ($response) = @_;
            is( $response->{status}, 'error', 'client1: slow request times out locally' );
            like( $response->{error}, qr/timed out/, 'client1: slow timeout message' );
        },
    );
}

# ---------------------------------------------------------------------------
# Track 2: event-style dispatch from a separate POE session.
# ---------------------------------------------------------------------------
my $client2;
$client2 = POE::Component::Server::JSONUnix::Client->spawn(
    socket_path => $sock_a,
    alias       => 'client2',
    on_connect  => sub { $poe_kernel->post( event_driver => 'client_ready' ) },
);

POE::Session->create(
    inline_states => {
        _start       => sub { $_[KERNEL]->alias_set('event_driver') },
        client_ready => sub {

            # Called from inside this session, so the response event comes
            # back here.
            $client2->call(
                command => 'echo',
                args    => { via => 'event' },
                event   => 'got_response',
                context => 'event-context',
            );
        },
        got_response => sub {
            my ( $kernel, $response, $context ) = @_[ KERNEL, ARG0, ARG1 ];
            is( $response->{status}, 'ok', 'client2: event-style response delivered' );
            is_deeply( $response->{result}{args}, { via => 'event' }, 'client2: event-style payload' );
            is( $context, 'event-context', 'client2: event-style context as ARG1' );
            $client2->shutdown;
            $kernel->alias_remove('event_driver');
            track_done();
        },
    },
);

# ---------------------------------------------------------------------------
# Track 3: explicit authenticate() against the auth-required server.
# ---------------------------------------------------------------------------
my $client3;
$client3 = POE::Component::Server::JSONUnix::Client->spawn(
    socket_path => $sock_b,
    alias       => 'client3',
    on_connect  => sub {
        my ($c) = @_;
        ok( !$c->authenticated, 'client3: not authenticated before handshake' );

        $c->call(
            command  => 'whoami',
            callback => sub {
                my ($response) = @_;
                is( $response->{status}, 'error', 'client3: gated command rejected before auth' );
                like( $response->{error}, qr/authentication required/i, 'client3: gating message' );

                $c->authenticate(
                    callback => sub {
                        my ($auth) = @_;
                        is( $auth->{status},           'ok',         'client3: authenticate() ok' );
                        is( $auth->{result}{uid},      $my_uid,      'client3: handshake reports our uid' );
                        is( $auth->{result}{username}, $my_username, 'client3: handshake reports our username' );
                        ok( $c->authenticated, 'client3: authenticated() true after handshake' );
                        is( $c->uid,      $my_uid,      'client3: uid() accessor' );
                        is( $c->username, $my_username, 'client3: username() accessor' );

                        $c->call(
                            command  => 'whoami',
                            callback => sub {
                                my ($whoami) = @_;
                                is( $whoami->{status}, 'ok', 'client3: gated command works after auth' );
                                is( $whoami->{result}{uid}, $my_uid, 'client3: server-side ctx->uid correct' );
                                $c->shutdown;
                                track_done();
                            },
                        );
                    },
                );
            },
        );
    },
);

# ---------------------------------------------------------------------------
# Track 4: auto_auth + on_auth. Stays connected until the finale so the
# finale can watch auth state get cleared by the disconnect.
# ---------------------------------------------------------------------------
my $client4;
$client4 = POE::Component::Server::JSONUnix::Client->spawn(
    socket_path => $sock_b,
    alias       => 'client4',
    auto_auth   => 1,
    on_auth     => sub {
        my ( $c, $response ) = @_;
        is( $response->{status}, 'ok', 'client4: auto_auth handshake ok' );
        ok( $c->authenticated, 'client4: authenticated() true after auto_auth' );
        is( $c->uid, $my_uid, 'client4: uid() correct after auto_auth' );
        track_done();
    },
    on_disconnect => sub {
        my ( $c, $reason ) = @_;
        ok( !$c->authenticated, 'client4: auth state cleared on disconnect' );
        ok( !$c->connected,     'client4: connected() false after disconnect' );
        $disconnects{client4} = 1;
        finale_step2();
    },
);

# ---------------------------------------------------------------------------
# Track 5: calling while not connected (auto_connect off) answers locally.
# ---------------------------------------------------------------------------
my $client5;
$client5 = POE::Component::Server::JSONUnix::Client->spawn(
    socket_path  => $sock_a,
    alias        => 'client5',
    auto_connect => 0,
);
ok( !$client5->connected, 'client5: not connected with auto_connect off' );
$client5->call(
    command  => 'ping',
    callback => sub {
        my ($response) = @_;
        is( $response->{status}, 'error', 'client5: call while disconnected errors' );
        like( $response->{error}, qr/not connected/, 'client5: not-connected message' );
        $client5->shutdown;
        track_done();
    },
);

# ---------------------------------------------------------------------------
# Track 6: connect failure. The request queued during the attempt must be
# answered with an error, and on_error must fire.
# ---------------------------------------------------------------------------
my $client6;
my $client6_saw_error = 0;
$client6 = POE::Component::Server::JSONUnix::Client->spawn(
    socket_path => "$dir/no_such_server.sock",
    alias       => 'client6',
    on_error    => sub { $client6_saw_error++ },
);
$client6->call(
    command  => 'ping',
    callback => sub {
        my ($response) = @_;
        is( $response->{status}, 'error', 'client6: queued request fails when connect fails' );
        like( $response->{error}, qr/connect failed/, 'client6: connect-failure message' );
        ok( $client6_saw_error, 'client6: on_error fired for the failed connect' );
        $client6->shutdown;
        track_done();
    },
);

# ---------------------------------------------------------------------------
# Finale: shut the servers down and confirm the still-connected clients see
# it as a disconnect, then let the kernel drain.
# ---------------------------------------------------------------------------
sub finale {
    $server_a->shutdown;
    $server_b->shutdown;
    # finale_step2() runs from client1's and client4's on_disconnect.
}

sub finale_step2 {
    return unless $disconnects{client1} && $disconnects{client4};
    $client1->shutdown;
    $client4->shutdown;
    $poe_kernel->post( slow_responder => 'shutdown' );
    $poe_kernel->post( watchdog       => 'all_done' );
}

$poe_kernel->run;

done_testing();
