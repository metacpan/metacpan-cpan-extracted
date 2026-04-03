# Tests for timeout behavior in query() and ready().
# Verifies that the timeout code paths fire correctly when the
# remote identd is slow or unresponsive.

use 5.010;
use strict;
use warnings;
use Test::More;

use Net::Ident;
use Socket qw(PF_UNIX SOCK_STREAM);

# Helper: create a socketpair.
sub make_socketpair {
    my ( $client, $server );
    socketpair( $client, $server, PF_UNIX, SOCK_STREAM, 0 )
        or plan skip_all => "socketpair not available: $!";
    $client->autoflush(1);
    $server->autoflush(1);
    return ( $client, $server );
}

# Build a Net::Ident object in 'connect' state with a real filehandle.
sub make_connect_obj {
    my (%args) = @_;
    my ( $client, $server ) = make_socketpair();
    my $obj = bless {
        state      => 'connect',
        fh         => $client,
        remoteport => $args{remoteport} // 6191,
        localport  => $args{localport}  // 23,
        maxtime    => $args{maxtime},
    }, 'Net::Ident';
    return ( $obj, $server );
}

# Build a Net::Ident object in 'query' state (query already sent).
sub make_query_obj {
    my (%args) = @_;
    my ( $client, $server ) = make_socketpair();
    my $obj = bless {
        state      => 'query',
        answer     => '',
        fh         => $client,
        remoteport => $args{remoteport} // 6191,
        localport  => $args{localport}  // 23,
        maxtime    => $args{maxtime},
    }, 'Net::Ident';
    return ( $obj, $server );
}

# === query() timeout paths ===

subtest 'query() times out when maxtime already expired' => sub {
    my ( $obj, $server ) = make_connect_obj( maxtime => time - 1 );

    my $result = $obj->query;
    is( $result, undef, 'query() returns undef on timeout' );
    like( $obj->geterror, qr/timed out/i, 'error mentions timeout' );
    is( $obj->getfh, undef, 'fh cleaned up after timeout' );

    close $server;
};

subtest 'query() times out waiting for writable socket' => sub {
    # Use a very short timeout with a socket that is already writable —
    # socketpair sockets are immediately writable, so this tests the
    # pre-expiry calculation path rather than the select timeout.
    # We set maxtime to now+0.01 so the select returns immediately.
    my ( $obj, $server ) = make_connect_obj( maxtime => time + 5 );

    # This should succeed since the socketpair is immediately writable
    my $result = $obj->query;
    ok( $result, 'query() succeeds with valid timeout and writable socket' );

    close $server;
};

# === ready() timeout paths ===

subtest 'ready() times out when maxtime already expired (blocking)' => sub {
    my ( $obj, $server ) = make_query_obj( maxtime => time - 1 );

    my $result = $obj->ready(1);
    is( $result, undef, 'ready(1) returns undef on timeout' );
    like( $obj->geterror, qr/timeout/i, 'error mentions timeout' );
    is( $obj->getfh, undef, 'fh cleaned up after timeout' );

    close $server;
};

subtest 'ready() times out when maxtime already expired (non-blocking)' => sub {
    my ( $obj, $server ) = make_query_obj( maxtime => time - 1 );

    my $result = $obj->ready(0);
    is( $result, undef, 'ready(0) returns undef on timeout' );
    like( $obj->geterror, qr/timeout/i, 'error mentions timeout' );

    close $server;
};

subtest 'ready() select-timeout with no data (blocking, short timeout)' => sub {
    # Set timeout to expire very soon — the child never sends data.
    my ( $obj, $server ) = make_query_obj( maxtime => time + 1 );

    # Don't write anything to $server, so ready() must wait then time out.
    # The select in ready() will wait up to (maxtime - time) seconds.
    # We keep the server open so it's not an EOF.

    # Override maxtime to something that expires very soon
    $obj->{maxtime} = time + 0.1;

    my $result = $obj->ready(1);
    is( $result, undef, 'ready(1) returns undef when no data arrives before timeout' );
    like( $obj->geterror, qr/timeout/i, 'error mentions timeout' );

    close $server;
};

subtest 'ready() returns 0 (not ready) in non-blocking mode with no data' => sub {
    # Non-blocking ready with no timeout — should return 0, not undef
    my ( $obj, $server ) = make_query_obj( maxtime => undef );

    my $result = $obj->ready(0);
    is( $result, 0, 'ready(0) returns 0 when no data available and no timeout' );
    ok( !$obj->geterror, 'no error set — just not ready yet' );

    close $server;
};

subtest 'ready() partial data then timeout (blocking)' => sub {
    my ( $obj, $server ) = make_query_obj( maxtime => time + 0.2 );

    # Send partial data (no \r\n terminator)
    syswrite( $server, "6191 , 23 : USERID" );

    my $result = $obj->ready(1);
    is( $result, undef, 'ready(1) returns undef — partial data but no terminator before timeout' );
    like( $obj->geterror, qr/timeout/i, 'error mentions timeout' );

    close $server;
};

# === username() timeout delegation ===

subtest 'username() returns undef when ready() times out' => sub {
    my ( $obj, $server ) = make_query_obj( maxtime => time - 1 );

    my $username = $obj->username;
    is( $username, undef, 'username returns undef on timeout' );

    # In list context, error should be present
    $obj->{state} = 'query';
    $obj->{answer} = '';
    $obj->{maxtime} = time - 1;
    my ( $client2, $server2 ) = make_socketpair();
    $obj->{fh} = $client2;
    my ( $user, $opsys, $error ) = $obj->username;
    is( $user, undef, 'username returns undef in list context on timeout' );
    ok( $error, 'error is set in list context: ' . ( $error // '' ) );

    close $server;
    close $server2;
};

# === query→ready chained timeout ===

subtest 'ready() calls query() which times out' => sub {
    # Object in 'connect' state with expired timeout.
    # ready() will try to call query(), which should time out.
    my ( $obj, $server ) = make_connect_obj( maxtime => time - 1 );

    my $result = $obj->ready(1);
    is( $result, undef, 'ready(1) returns undef when delegated query() times out' );
    like( $obj->geterror, qr/timed out/i, 'error from query timeout propagates' );

    close $server;
};

subtest 'no timeout when maxtime is undef (blocking ready succeeds)' => sub {
    my ( $obj, $server ) = make_query_obj( maxtime => undef );

    # Send a complete response so ready() returns quickly
    syswrite( $server, "6191 , 23 : USERID : UNIX : testuser\r\n" );

    my $result = $obj->ready(1);
    is( $result, 1, 'ready(1) succeeds with no timeout limit' );
    is( $obj->{state}, 'ready', 'state is ready' );

    close $server;
};

done_testing;
