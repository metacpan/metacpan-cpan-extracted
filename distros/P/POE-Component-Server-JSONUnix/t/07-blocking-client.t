use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Socket qw(PF_UNIX SOCK_STREAM);
use Time::HiRes qw(sleep);

BEGIN {
    unless ( eval { require POE; require JSON::MaybeXS; 1 } ) {
        plan skip_all =>
            'POE and JSON::MaybeXS are required for the blocking client test';
    }
}

plan skip_all => 'Unix domain sockets are unavailable'
    unless eval { socket( my $s, PF_UNIX, SOCK_STREAM, 0 ) };

plan skip_all => 'fork is unavailable'
    unless $Config::Config{d_fork} || $^O =~ /\A(?:linux|.*bsd|darwin|solaris)\z/;

use POE;
use POE::Component::Server::JSONUnix;
use POE::Component::Server::JSONUnix::BlockingClient;

my $dir      = tempdir( CLEANUP => 1 );
my $sock_a   = "$dir/plain.sock";     # no auth requirement
my $sock_b   = "$dir/auth.sock";      # auth_required
my $auth_tmp = "$dir/auth_files";
mkdir $auth_tmp or die "mkdir: $!";

my $my_uid      = $>;
my $my_username = ( getpwuid($my_uid) )[0] // '';

# ---------------------------------------------------------------------------
# The servers are POE-based, and the whole point of the blocking client is to
# live outside an event loop -- so run them in a forked child.
# ---------------------------------------------------------------------------

my $server_pid = fork();
die "fork failed: $!" unless defined $server_pid;

if ( $server_pid == 0 ) {
    # Answers 'slow' requests after a delay, from outside the server's
    # handler -- exercises the client's timeout-then-late-response path.
    POE::Session->create(
        inline_states => {
            _start       => sub { $_[KERNEL]->alias_set('slow_responder') },
            answer_later => sub {
                my ( $kernel, $ctx, $delay, $value ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
                $kernel->delay_set( answer => $delay, $ctx, $value );
            },
            answer => sub { my ( $ctx, $value ) = @_[ ARG0, ARG1 ]; $ctx->respond_result($value) },
        },
    );

    POE::Component::Server::JSONUnix->spawn(
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

    POE::Component::Server::JSONUnix->spawn(
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

    $poe_kernel->run;
    exit 0;
} ## end if ( $server_pid == 0 )

END {
    if ($server_pid) {
        local $?;    # keep waitpid from clobbering the test's exit status
        kill 'TERM', $server_pid;
        waitpid $server_pid, 0;
    }
}

# Wait for both sockets to come up.
for ( 1 .. 100 ) {
    last if -S $sock_a && -S $sock_b;
    sleep 0.1;
}
-S $sock_a && -S $sock_b
    or plan skip_all => 'server child did not create its sockets';

plan tests => 25;

# ---------------------------------------------------------------------------
# Basic request/response.
# ---------------------------------------------------------------------------

my $client = POE::Component::Server::JSONUnix::BlockingClient->new(
    socket_path => $sock_a,
    timeout     => 5,
);
ok( $client->connected, 'client connected on construction' );

my $pong = $client->call( command => 'ping' );
is( $pong->{status},         'ok', 'ping succeeded' );
is( $pong->{result}{pong},   1,    'ping returned pong' );

my $echo = $client->call( command => 'echo', args => { deep => [ 1, { two => 2 } ] } );
is( $echo->{status}, 'ok', 'echo succeeded' );
is_deeply( $echo->{result}{args}, { deep => [ 1, { two => 2 } ] }, 'echo returned the args payload' );

my $cmd_alias = $client->call( cmd => 'ping' );
is( $cmd_alias->{status}, 'ok', "'cmd' accepted as an alias for 'command'" );

my $unknown = $client->call( command => 'no_such_command' );
is( $unknown->{status}, 'error', 'unknown command reported as an error envelope' );
like( $unknown->{error}, qr/unknown command/, 'unknown command error message' );

# ---------------------------------------------------------------------------
# Timeouts and late responses.
# ---------------------------------------------------------------------------

my $timed_out = $client->call( command => 'blackhole', timeout => 0.3 );
is( $timed_out->{status}, 'error',             'unanswered request times out' );
is( $timed_out->{error},  'request timed out', 'timeout error message' );
ok( $client->connected, 'a timeout does not drop the connection' );

my @notices;
my $noticing_client = POE::Component::Server::JSONUnix::BlockingClient->new(
    socket_path => $sock_a,
    timeout     => 5,
    on_notice   => sub { push @notices, $_[1] },
);

my $slow = $noticing_client->call( command => 'slow', timeout => 0.3 );
is( $slow->{status}, 'error', 'slow request times out locally' );

sleep 1;    # let the server's delayed answer land in the socket buffer
my $after = $noticing_client->call( command => 'echo', args => { later => 1 } );
is( $after->{status}, 'ok', 'call after a timeout still works' );
is_deeply( $after->{result}{args}, { later => 1 }, 'and is answered by its own response' );
is( scalar @notices, 1, 'the late response was routed to on_notice' );
is_deeply( $notices[0]{result}, { slow => 1 }, 'on_notice received the late result' );

# ---------------------------------------------------------------------------
# Disconnect / reconnect.
# ---------------------------------------------------------------------------

$client->disconnect;
ok( !$client->connected, 'disconnect drops the connection' );

my $while_down = $client->call( command => 'ping' );
is( $while_down->{status}, 'error',         'call while disconnected returns an error envelope' );
is( $while_down->{error},  'not connected', 'not-connected error message' );

$client->connect;
is( $client->call( command => 'ping' )->{status}, 'ok', 'reconnect works' );

# ---------------------------------------------------------------------------
# Authentication.
# ---------------------------------------------------------------------------

SKIP: {
    skip 'could not resolve own username', 5 unless length $my_username;

    my $auth_client = POE::Component::Server::JSONUnix::BlockingClient->new(
        socket_path => $sock_b,
        timeout     => 5,
    );

    my $gated = $auth_client->call( command => 'whoami' );
    is( $gated->{status}, 'error', 'auth_required gates commands before authentication' );

    my $auth = $auth_client->authenticate;
    is( $auth->{status}, 'ok', 'authenticate succeeded' )
        or diag explain $auth;
    is( $auth_client->uid, $my_uid, 'uid accessor reflects the verified identity' );

    my $me = $auth_client->call( command => 'whoami' );
    is( $me->{status}, 'ok', 'whoami allowed after authentication' );
    is_deeply(
        $me->{result},
        { uid => $my_uid, username => $my_username },
        'server sees the authenticated identity'
    );
} ## end SKIP:
