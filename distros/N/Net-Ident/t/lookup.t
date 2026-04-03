# Tests for the convenience lookup functions: lookupFromInAddr()
# and lookup().  These are the procedural interface to Net::Ident,
# wrapping the OO new/newFromInAddr → username pipeline.
#
# Most of these tests run without a network identd by using loopback
# sockets that will fail at the identd connect stage — but they
# exercise the full code path through to username() and verify
# correct return values in both scalar and list context.

use 5.010;
use strict;
use warnings;
use Test::More;

use Net::Ident qw(lookup lookupFromInAddr ident_lookup);
use Socket;
use IO::Socket::INET;

# --- lookupFromInAddr: scalar context (no identd) ---
subtest 'lookupFromInAddr scalar context without identd' => sub {
    # Build sockaddr_in structs for a loopback connection.
    # We bind a listener so the local address is real, then forge the
    # remote address.  The ident connect to 127.0.0.1:113 will fail.
    my $local  = sockaddr_in( 9999, inet_aton('127.0.0.1') );
    my $remote = sockaddr_in( 8888, inet_aton('127.0.0.1') );

    my $result = lookupFromInAddr( $local, $remote, 2 );
    is( $result, undef, 'returns undef when no identd is running' );
};

# --- lookupFromInAddr: list context (no identd) ---
subtest 'lookupFromInAddr list context without identd' => sub {
    my $local  = sockaddr_in( 9999, inet_aton('127.0.0.1') );
    my $remote = sockaddr_in( 8888, inet_aton('127.0.0.1') );

    my ( $user, $opsys, $error ) = lookupFromInAddr( $local, $remote, 2 );
    is( $user,  undef, 'user is undef' );
    ok( $error, "error is set: " . ( $error // '<none>' ) );
};

# --- lookup: scalar context with connected socket (no identd) ---
subtest 'lookup with connected socket, scalar context' => sub {
    my $listener = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
    );
    plan skip_all => 'cannot create listener socket' unless $listener;

    my $port = $listener->sockport;
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
    );
    plan skip_all => 'cannot connect to listener' unless $client;
    my $server = $listener->accept;

    my $result = lookup( $client, 2 );
    is( $result, undef, 'lookup returns undef when no identd' );

    close($client);
    close($server);
    close($listener);
};

# --- lookup: list context with connected socket (no identd) ---
subtest 'lookup with connected socket, list context' => sub {
    my $listener = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
    );
    plan skip_all => 'cannot create listener socket' unless $listener;

    my $port = $listener->sockport;
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
    );
    plan skip_all => 'cannot connect to listener' unless $client;
    my $server = $listener->accept;

    my ( $user, $opsys, $error ) = lookup( $client, 2 );
    is( $user, undef, 'user is undef when no identd' );
    ok( $error, "error is set: " . ( $error // '<none>' ) );

    close($client);
    close($server);
    close($listener);
};

# --- ident_lookup is an alias for lookup ---
subtest 'ident_lookup alias works identically to lookup' => sub {
    my $listener = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
    );
    plan skip_all => 'cannot create listener socket' unless $listener;

    my $port = $listener->sockport;
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
    );
    plan skip_all => 'cannot connect to listener' unless $client;
    my $server = $listener->accept;

    my $result = ident_lookup( $client, 2 );
    is( $result, undef, 'ident_lookup returns undef when no identd' );

    close($client);
    close($server);
    close($listener);
};

# --- lookup with bad filehandle ---
subtest 'lookup with non-socket filehandle' => sub {
    my $result = lookup( \*STDERR, 2 );
    is( $result, undef, 'lookup on non-socket returns undef' );
};

# --- lookupFromInAddr with different local/remote addresses ---
subtest 'lookupFromInAddr with unreachable remote' => sub {
    # 192.0.2.1 (TEST-NET-1) — guaranteed non-routable
    my $local  = sockaddr_in( 12345, inet_aton('127.0.0.1') );
    my $remote = sockaddr_in( 80, inet_aton('192.0.2.1') );

    my ( $user, $opsys, $error ) = lookupFromInAddr( $local, $remote, 1 );
    is( $user, undef, 'user is undef for unreachable remote' );
    ok( $error, "error for unreachable remote: " . ( $error // '<none>' ) );
};

done_testing;
