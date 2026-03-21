# Unit tests for Net::Ident query() method.
# Tests the ident protocol query phase using socketpair,
# without needing a running identd or network access.

use 5.010;
use strict;
use warnings;
use Test::More;

use Net::Ident;
use Socket qw(PF_UNIX SOCK_STREAM);

# socketpair gives us a bidirectional pipe — one end acts as the
# "identd connection", the other we hand to Net::Ident as its fh.
sub make_socketpair {
    my ( $client, $server );
    socketpair( $client, $server, PF_UNIX, SOCK_STREAM, 0 )
        or plan skip_all => "socketpair not available: $!";
    $client->autoflush(1);
    $server->autoflush(1);
    return ( $client, $server );
}

# Read from a socket, waiting for data to arrive first.
# On Windows, socketpair is emulated via TCP so data may not be
# immediately available for a non-blocking read after the other end
# writes.  A brief select() ensures we wait for it.
sub read_from_peer {
    my ($fh) = @_;
    my $rmask = '';
    vec( $rmask, fileno($fh), 1 ) = 1;
    select( $rmask, undef, undef, 2 );
    my $buf = '';
    $fh->blocking(0);
    sysread( $fh, $buf, 1000 );
    return $buf;
}

# Build a Net::Ident object in 'connect' state with a real filehandle.
sub make_connected {
    my (%args) = @_;
    my ( $client, $server ) = make_socketpair();
    my $obj = bless {
        state      => 'connect',
        fh         => $client,
        remoteport => $args{remoteport} // 6191,
        localport  => $args{localport}  // 23,
        maxtime    => defined $args{timeout} ? time + $args{timeout} : undef,
    }, 'Net::Ident';
    return ( $obj, $server );
}

# --- query() sends correct protocol string ---

subtest 'query sends correct ident protocol string' => sub {
    my ( $obj, $server ) = make_connected(
        remoteport => 6191,
        localport  => 23,
    );

    my $result = $obj->query;
    ok( $result, 'query() returns true on success' );
    is( ref $result, 'Net::Ident', 'query() returns the object itself' );

    # Read what was sent to the server end
    my $sent = read_from_peer($server);
    is( $sent, "6191,23\r\n", 'correct ident query sent (remoteport,localport\\r\\n)' );

    close $server;
};

subtest 'query transitions state to query' => sub {
    my ( $obj, $server ) = make_connected();

    is( $obj->{state}, 'connect', 'state starts as connect' );
    $obj->query;
    is( $obj->{state}, 'query', 'state transitions to query after query()' );

    close $server;
};

subtest 'query initialises empty answer buffer' => sub {
    my ( $obj, $server ) = make_connected();

    $obj->query;
    is( $obj->{answer}, '', 'answer buffer initialised to empty string' );

    close $server;
};

# --- query() with different port values ---

subtest 'query with high port numbers' => sub {
    my ( $obj, $server ) = make_connected(
        remoteport => 65535,
        localport  => 49152,
    );

    $obj->query;

    my $sent = read_from_peer($server);
    is( $sent, "65535,49152\r\n", 'high port numbers formatted correctly' );

    close $server;
};

subtest 'query with port 1' => sub {
    my ( $obj, $server ) = make_connected(
        remoteport => 1,
        localport  => 1,
    );

    $obj->query;

    my $sent = read_from_peer($server);
    is( $sent, "1,1\r\n", 'low port numbers formatted correctly' );

    close $server;
};

# --- query() error conditions ---

subtest 'query returns undef when no fh' => sub {
    my $obj = bless {
        state      => 'connect',
        remoteport => 6191,
        localport  => 23,
    }, 'Net::Ident';

    is( $obj->query, undef, 'query returns undef when fh is missing' );
};

subtest 'query returns undef when called in wrong state' => sub {
    my ( $obj, $server ) = make_connected();

    # Set state to something other than 'connect'
    $obj->{state} = 'ready';
    my $result = $obj->query;
    is( $result, undef, 'query returns undef when state is not connect' );
    like( $obj->geterror, qr/wrong order/i, 'error mentions wrong order' );

    close $server;
};

subtest 'query on error-state object returns undef' => sub {
    my $obj = bless {
        state => 'error',
        error => "Net::Ident::new: fh undef\n",
    }, 'Net::Ident';

    is( $obj->query, undef, 'query returns undef for error-state object' );
};

# --- Full end-to-end: query → ready → username ---

subtest 'end-to-end: query then ready then username' => sub {
    my ( $obj, $server ) = make_connected(
        remoteport => 6191,
        localport  => 23,
        timeout    => 5,
    );

    # Phase 1: query
    ok( $obj->query, 'query succeeds' );
    is( $obj->{state}, 'query', 'state is query' );

    # Phase 2: server reads the query and sends a response
    my $query_str = read_from_peer($server);
    is( $query_str, "6191,23\r\n", 'server received correct query' );

    # Server sends ident response.  Use shutdown() to send FIN before
    # close — on Windows, close() alone can send RST which destroys
    # buffered data before the client reads it.
    print $server "6191, 23 : USERID : UNIX : testuser\r\n";
    shutdown( $server, 1 );
    close $server;

    # Phase 3: ready
    my $ready = $obj->ready(1);
    is( $ready, 1, 'ready returns 1 after response received' );
    is( $obj->{state}, 'ready', 'state is ready' );

    # Phase 4: username
    my ( $user, $opsys, $error ) = $obj->username;
    is( $user,  'testuser', 'username parsed correctly' );
    is( $opsys, 'UNIX',     'opsys parsed correctly' );
    is( $error, undef,      'no error' );
};

subtest 'end-to-end: query then ERROR response' => sub {
    my ( $obj, $server ) = make_connected(
        remoteport => 6191,
        localport  => 23,
        timeout    => 5,
    );

    $obj->query;

    # Drain query, send ERROR response
    read_from_peer($server);
    print $server "6191, 23 : ERROR : NO-USER\r\n";
    shutdown( $server, 1 );
    close $server;

    my ( $user, $opsys, $error ) = $obj->username;
    is( $user,  undef,     'username undef on ERROR' );
    is( $opsys, 'ERROR',   'opsys is ERROR' );
    is( $error, 'NO-USER', 'error is NO-USER' );
};

subtest 'end-to-end: auto-query from ready' => sub {
    # ready() should call query() automatically if state is 'connect'
    my ( $obj, $server ) = make_connected(
        remoteport => 6191,
        localport  => 23,
        timeout    => 5,
    );

    is( $obj->{state}, 'connect', 'starts in connect state' );

    # Write response to server end before calling ready —
    # use a fork so the response arrives after query sends its request
    my $pid = fork();
    if ( !defined $pid ) {
        plan skip_all => "fork not available: $!";
    }
    if ( $pid == 0 ) {
        # child: wait briefly, read query, send response
        close $obj->{fh};    # close client end in child
        my $q = '';
        $server->blocking(1);
        sysread( $server, $q, 1000 );
        print $server "6191, 23 : USERID : UNIX : autouser\r\n";
        shutdown( $server, 1 );
        close $server;
        exit 0;
    }

    # parent
    close $server;    # close server end in parent
    my $ready = $obj->ready(1);
    is( $ready, 1, 'ready auto-queries and succeeds' );

    my $user = scalar $obj->username;
    is( $user, 'autouser', 'username from auto-queried flow' );

    waitpid( $pid, 0 );
};

done_testing;
