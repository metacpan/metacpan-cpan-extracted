# -*- Perl -*-
# Tests for Net::Ident constructor (new, newFromInAddr) and _passfh
# filehandle resolution.  These run without a network identd by
# exercising error paths and verifying object state.

use 5.010;
use strict;
use warnings;

use Test::More;
use Net::Ident;
use Socket;
use IO::Socket::INET;

# --- new() with various filehandle passing styles ---
# new() always returns an object (never dies), but sets error state
# when the handle isn't a connected socket.

# 1. glob reference (the modern style)
{
    my $obj = Net::Ident->new( \*STDERR, 5 );
    ok( $obj, 'new(\\*STDERR): returns object' );
    ok( $obj->geterror, 'new(\\*STDERR): has error' );
    is( $obj->getfh, undef, 'new(\\*STDERR): no fh on error' );
}

# 2. undef filehandle
{
    my $obj = Net::Ident->new( undef, 5 );
    ok( $obj, 'new(undef): returns object' );
    like( $obj->geterror, qr/fh undef/i, 'new(undef): error mentions undef fh' );
    is( $obj->getfh, undef, 'new(undef): no fh on error' );
}

# 3. FileHandle object (not a socket)
{
    require FileHandle;
    my $fh = FileHandle->new;
    open( $fh, '<', $0 ) or die "cannot open $0: $!";
    my $obj = Net::Ident->new( $fh, 5 );
    ok( $obj, 'new(FileHandle): returns object' );
    ok( $obj->geterror, 'new(FileHandle): has error (not a socket)' );
    close($fh);
}

# 4. Bare glob (string form) — exercises _passfh caller resolution
{
    # Create a real filehandle in the current package
    open( my $orig, '<', $0 ) or die "cannot open $0: $!";
    no strict 'refs';
    *{"main::TESTFH"} = $orig;
    use strict 'refs';

    my $obj = Net::Ident->new( 'TESTFH', 5 );
    ok( $obj, 'new("TESTFH"): returns object for bare string' );
    ok( $obj->geterror, 'new("TESTFH"): error (not a socket)' );
    # Key: _passfh resolved the unqualified name without crashing
    like( $obj->geterror, qr/getsockname|getpeername/i,
        'new("TESTFH"): error is from socket ops, not name resolution' );
    close($orig);
}

# 5. Fully qualified glob string — _passfh skips caller resolution
{
    open( my $orig, '<', $0 ) or die "cannot open $0: $!";
    no strict 'refs';
    *{"main::TESTFH2"} = $orig;
    use strict 'refs';

    my $obj = Net::Ident->new( 'main::TESTFH2', 5 );
    ok( $obj, 'new("main::TESTFH2"): returns object for qualified name' );
    ok( $obj->geterror, 'new("main::TESTFH2"): error (not a socket)' );
    close($orig);
}

# --- Error-state object: all methods return undef except geterror ---
{
    my $obj = Net::Ident->new( undef, 5 );
    is( $obj->getfh, undef, 'error object: getfh returns undef' );
    is( $obj->query, undef, 'error object: query returns undef' );
    is( $obj->ready, undef, 'error object: ready returns undef' );

    my ( $user, $opsys, $error ) = $obj->username;
    is( $user, undef, 'error object: username returns undef' );
    ok( $error, 'error object: username error in list context' );

    my $scalar_user = $obj->username;
    is( $scalar_user, undef, 'error object: username returns undef in scalar context' );
}

# --- newFromInAddr with valid local address ---
# Uses 127.0.0.1 as local and 192.0.2.1 (TEST-NET-1) as remote.
# The connect to 192.0.2.1:113 will fail (bind may succeed but connect won't).
{
    my $local  = sockaddr_in( 12345, inet_aton('127.0.0.1') );
    my $remote = sockaddr_in( 12345, inet_aton('192.0.2.1') );
    my $obj    = Net::Ident->newFromInAddr( $local, $remote, 2 );
    ok( $obj, 'newFromInAddr(127.0.0.1, 192.0.2.1): returns object' );
    # Either gets an error from bind/connect or creates a connection object
    # On most systems, bind to 127.0.0.1 succeeds but connect to TEST-NET fails
    if ( $obj->geterror ) {
        like( $obj->geterror, qr/bind|connect/i,
            'newFromInAddr: error is from bind or connect' );
    }
    else {
        ok( $obj->getfh, 'newFromInAddr: has fh when no immediate error' );
    }
}

# --- new() with a real socket (not connected) ---
# A socket that exists but isn't connected should fail on getsockname/getpeername
{
    socket( my $sock, PF_INET, SOCK_STREAM, getprotobyname('tcp') || 6 )
        or die "socket: $!";
    my $obj = Net::Ident->new( $sock, 5 );
    ok( $obj, 'new(unconnected socket): returns object' );
    ok( $obj->geterror, 'new(unconnected socket): has error' );
    close($sock);
}

# --- new() with a connected socket (loopback, no identd) ---
# Creates a TCP listener, connects to it, then does an ident lookup.
# Without identd, the lookup will fail at connect to port 113.
SKIP: {
    my $listener = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
    );
    skip 'cannot create listener socket', 4 unless $listener;

    my $port = $listener->sockport;
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
    );
    skip 'cannot connect to listener', 4 unless $client;
    my $server = $listener->accept;
    skip 'accept failed', 4 unless $server;

    # This exercises the full new() path: _passfh, getsockname, getpeername,
    # newFromInAddr.  The ident connect to 127.0.0.1:113 will likely fail.
    my $obj = Net::Ident->new( $client, 2 );
    ok( $obj, 'new(connected socket): returns object' );

    # The object should have extracted the correct ports
    if ( !$obj->geterror ) {
        ok( $obj->getfh, 'new(connected socket): has ident fh' );

        # query + ready should eventually fail (no identd)
        my ( $user, $opsys, $error ) = $obj->username;
        ok( !defined $user, 'no identd: username is undef' );
        ok( $error, "no identd: got error: " . ( $error // '<undef>' ) );
    }
    else {
        # On some systems, connect to 113 fails immediately
        like( $obj->geterror, qr/connect|refused|timed/i,
            'new(connected socket): error from ident connect' );
        pass('skipping username test — ident connect failed immediately');
        pass('skipping username test — ident connect failed immediately');
    }

    close($client);
    close($server);
    close($listener);
}

done_testing;
