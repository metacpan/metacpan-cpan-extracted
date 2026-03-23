# Tests for the Net::Ident async (non-blocking) interface: query(), ready(),
# getfh(), and the state machine transitions.  Uses socketpair for real I/O
# without needing a running identd or network access.

use 5.010;
use strict;
use warnings;
use Test::More;

use Net::Ident;
use Socket qw(PF_UNIX SOCK_STREAM);

# Helper: create a socketpair and return both ends.
# The "ident" end goes into the Net::Ident object's {fh};
# the "remote" end is what we write/read to simulate the remote identd.
sub make_socketpair {
    my ($ident_end, $remote_end);
    socketpair($ident_end, $remote_end, PF_UNIX, SOCK_STREAM, 0)
        or plan skip_all => "socketpair not available: $!";
    $remote_end->autoflush(1);
    return ($ident_end, $remote_end);
}

# Helper: build a Net::Ident object in 'connect' state with a socketpair fh,
# bypassing the real connect-to-identd logic.
sub make_connect_obj {
    my (%args) = @_;
    my ($ident_end, $remote_end) = make_socketpair();
    my $obj = bless {
        state      => 'connect',
        fh         => $ident_end,
        remoteport => $args{remoteport} // 6191,
        localport  => $args{localport}  // 23,
        maxtime    => defined $args{timeout} ? time + $args{timeout} : undef,
    }, 'Net::Ident';
    return ($obj, $remote_end);
}

# Helper: build a Net::Ident object in 'query' state (query already sent).
sub make_query_obj {
    my (%args) = @_;
    my ($ident_end, $remote_end) = make_socketpair();
    my $obj = bless {
        state      => 'query',
        answer     => '',
        fh         => $ident_end,
        remoteport => $args{remoteport} // 6191,
        localport  => $args{localport}  // 23,
        maxtime    => defined $args{timeout} ? time + $args{timeout} : undef,
    }, 'Net::Ident';
    return ($obj, $remote_end);
}


# === query() method ===

subtest 'query sends correct ident request' => sub {
    my ($obj, $remote) = make_connect_obj(remoteport => 6191, localport => 23);

    my $result = $obj->query;
    ok($result, 'query() returns truthy on success');
    is($obj->{state}, 'query', 'state transitions to query');

    # Read what query() sent from the remote end
    my $buf;
    sysread($remote, $buf, 100);
    is($buf, "6191,23\r\n", 'query sends "remoteport,localport\\r\\n"');

    close $remote;
};

subtest 'query initialises empty answer' => sub {
    my ($obj, $remote) = make_connect_obj();
    $obj->query;
    is($obj->{answer}, '', 'answer initialised to empty string after query');
    close $remote;
};

subtest 'query returns undef when state is not connect' => sub {
    my ($obj, $remote) = make_connect_obj();

    # Force wrong state
    $obj->{state} = 'ready';
    my $result = $obj->query;
    is($result, undef, 'query returns undef when state is ready');

    close $remote;
};

subtest 'query returns undef when no fh' => sub {
    my $obj = bless {
        state      => 'connect',
        remoteport => 6191,
        localport  => 23,
    }, 'Net::Ident';
    my $result = $obj->query;
    is($result, undef, 'query returns undef when fh is missing');
};


# === ready() method — non-blocking ===

subtest 'ready(0) returns 0 when no data available' => sub {
    my ($obj, $remote) = make_query_obj();

    # Don't write anything to the remote end
    my $result = $obj->ready(0);
    is($result, 0, 'ready(0) returns 0 when no data yet');
    is($obj->{state}, 'query', 'state remains query');

    close $remote;
};

subtest 'ready(0) returns 1 when complete response available' => sub {
    my ($obj, $remote) = make_query_obj(remoteport => 6191, localport => 23);

    # Write a complete ident response (with \r\n)
    print $remote "6191, 23 : USERID : UNIX : testuser\r\n";

    # Give the kernel a moment to propagate data through the socketpair
    select(undef, undef, undef, 0.05);

    my $result = $obj->ready(0);
    is($result, 1, 'ready(0) returns 1 when complete response available');
    is($obj->{state}, 'ready', 'state transitions to ready');
    like($obj->{answer}, qr/testuser/, 'answer contains the response');

    close $remote;
};

subtest 'ready(0) accumulates partial data' => sub {
    my ($obj, $remote) = make_query_obj();

    # Send partial data (no newline)
    print $remote "6191, 23 : USER";
    select(undef, undef, undef, 0.05);

    my $result = $obj->ready(0);
    is($result, 0, 'ready(0) returns 0 on partial data');
    is($obj->{answer}, '6191, 23 : USER', 'partial data accumulated');

    # Now send the rest
    print $remote "ID : UNIX : bob\r\n";
    select(undef, undef, undef, 0.05);

    $result = $obj->ready(0);
    is($result, 1, 'ready(0) returns 1 after remaining data arrives');
    is($obj->{state}, 'ready', 'state is ready');

    close $remote;
};

subtest 'ready strips data after CR/LF' => sub {
    my ($obj, $remote) = make_query_obj(remoteport => 6191, localport => 23);

    print $remote "6191, 23 : USERID : UNIX : alice\r\ngarbage after";
    select(undef, undef, undef, 0.05);

    $obj->ready(0);
    is($obj->{answer}, '6191, 23 : USERID : UNIX : alice',
        'answer stripped at CR/LF boundary');

    close $remote;
};


# === ready() method — blocking ===

subtest 'ready(1) blocks until complete response' => sub {
    my ($obj, $remote) = make_query_obj(remoteport => 6191, localport => 23,
                                         timeout => 5);

    # Write response in a subprocess after a brief delay
    my $pid = fork();
    if (!defined $pid) {
        plan skip_all => "fork not available: $!";
    }
    if ($pid == 0) {
        # child: wait briefly then send data
        close $obj->{fh};  # child doesn't need the ident end
        select(undef, undef, undef, 0.1);
        print $remote "6191, 23 : USERID : UNIX : delayed\r\n";
        shutdown($remote, 1);
        close $remote;
        exit 0;
    }

    # parent: ready(1) should block until child sends data.
    # Do NOT close $remote here — on Solaris, closing one end of a
    # PF_UNIX socketpair can immediately invalidate the other end,
    # even across fork.
    my $result = $obj->ready(1);
    waitpid($pid, 0);
    close $remote;

    is($result, 1, 'ready(1) returns 1 after blocking for data');
    like($obj->{answer}, qr/delayed/, 'got the delayed response');
};


# === ready() auto-calls query() ===

subtest 'ready auto-calls query when state is connect' => sub {
    my ($obj, $remote) = make_connect_obj(remoteport => 6191, localport => 23,
                                           timeout => 5);

    # Write the ident response before calling ready — it will query first,
    # then read.  We need a subprocess because query() blocks on select().
    my $pid = fork();
    if (!defined $pid) {
        plan skip_all => "fork not available: $!";
    }
    if ($pid == 0) {
        close $obj->{fh};
        # Read the query that ready()/query() will send
        my $buf;
        sysread($remote, $buf, 100);
        # Send response
        print $remote "6191, 23 : USERID : UNIX : auto\r\n";
        shutdown($remote, 1);
        close $remote;
        exit 0;
    }

    # Don't close $remote before ready() — see Solaris note above.
    my $result = $obj->ready(1);
    waitpid($pid, 0);
    close $remote;

    is($result, 1, 'ready(1) succeeded after auto-calling query');
    is($obj->{state}, 'ready', 'state is ready');
    like($obj->{answer}, qr/auto/, 'response parsed correctly');
};


# === ready() returns 1 immediately when already ready ===

subtest 'ready returns 1 when already in ready state' => sub {
    my $obj = bless {
        state      => 'ready',
        answer     => '6191, 23 : USERID : UNIX : joe',
        remoteport => 6191,
        localport  => 23,
    }, 'Net::Ident';

    is($obj->ready(0), 1, 'ready(0) returns 1 when already ready');
    is($obj->ready(1), 1, 'ready(1) returns 1 when already ready');
};


# === ready() EOF handling ===

subtest 'ready returns undef on EOF' => sub {
    my ($obj, $remote) = make_query_obj(timeout => 5);

    # Close remote end immediately (EOF with no data).
    # On Solaris, sysread may return ESPIPE instead of 0; the module
    # treats ESPIPE as EOF so this test passes on both platforms.
    close $remote;
    select(undef, undef, undef, 0.05);

    my $result = $obj->ready(1);
    is($result, undef, 'ready returns undef on immediate EOF');
    like($obj->geterror, qr/closed connection/i, 'error mentions closed connection');
};

subtest 'ready returns undef on EOF after partial data' => sub {
    my ($obj, $remote) = make_query_obj(timeout => 5);

    # Send partial data then close
    print $remote "6191, 23 : USER";
    close $remote;
    select(undef, undef, undef, 0.05);

    my $result = $obj->ready(1);
    is($result, undef, 'ready returns undef on EOF mid-response');
};


# === ready() babble protection ===

subtest 'ready returns undef when remote sends too much data' => sub {
    my ($obj, $remote) = make_query_obj(timeout => 5);

    # Send more than 1000 bytes without a newline
    print $remote "x" x 1100;
    close $remote;
    select(undef, undef, undef, 0.05);

    my $result = $obj->ready(1);
    is($result, undef, 'ready returns undef on babbling remote');
    like($obj->geterror, qr/babbling/i, 'error mentions babbling');
};


# === getfh() ===

subtest 'getfh returns the internal filehandle' => sub {
    my ($obj, $remote) = make_connect_obj();

    my $fh = $obj->getfh;
    ok(defined $fh, 'getfh returns a defined value');
    ok(fileno($fh), 'returned fh has a valid fileno');

    close $remote;
};

subtest 'getfh returns undef after error' => sub {
    my ($obj, $remote) = make_query_obj(timeout => 5);
    close $remote;
    select(undef, undef, undef, 0.05);

    # Trigger the error
    $obj->ready(1);

    is($obj->getfh, undef, 'getfh returns undef after error (fh deleted)');
};


# === Full async workflow end-to-end ===

subtest 'full async workflow: query -> ready -> username' => sub {
    my ($obj, $remote) = make_connect_obj(remoteport => 6191, localport => 23,
                                           timeout => 5);

    # Step 1: query
    ok($obj->query, 'query succeeds');

    # Verify the query was sent
    my $buf;
    sysread($remote, $buf, 100);
    is($buf, "6191,23\r\n", 'correct query sent');

    # Step 2: send response
    print $remote "6191, 23 : USERID : UNIX : asyncuser\r\n";
    select(undef, undef, undef, 0.05);

    # Step 3: ready (non-blocking)
    is($obj->ready(0), 1, 'ready returns 1');

    # Step 4: parse username
    my ($user, $opsys, $error) = $obj->username;
    is($user,  'asyncuser', 'username parsed from async flow');
    is($opsys, 'UNIX',      'opsys parsed correctly');
    is($error, undef,       'no error');

    close $remote;
};

subtest 'full async workflow with ERROR response' => sub {
    my ($obj, $remote) = make_connect_obj(remoteport => 6191, localport => 23,
                                           timeout => 5);

    $obj->query;

    # Consume the query
    my $buf;
    sysread($remote, $buf, 100);

    # Send an ERROR response
    print $remote "6191, 23 : ERROR : HIDDEN-USER\r\n";
    select(undef, undef, undef, 0.05);

    is($obj->ready(0), 1, 'ready returns 1 for ERROR response');

    my ($user, $opsys, $error) = $obj->username;
    is($user,  undef,         'username undef on ERROR');
    is($opsys, 'ERROR',       'opsys is ERROR');
    is($error, 'HIDDEN-USER', 'error string extracted');

    close $remote;
};


done_testing;
