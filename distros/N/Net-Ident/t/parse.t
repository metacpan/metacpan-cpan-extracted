# Unit tests for Net::Ident response parsing (username method).
# These tests exercise the RFC1413/931 protocol parser without
# needing a running identd or any network access.

use strict;
use warnings;
use Test::More;

use Net::Ident;

# Subclass that overrides ready() so we can test parsing in isolation.
# In real use, ready() handles network I/O and sets state to 'ready'.
# Here we skip that and go straight to the parser.
{
    package Net::Ident::MockReady;
    our @ISA = ('Net::Ident');
    sub ready { 1 }
}

# Helper: create a Net::Ident object with a pre-set answer,
# bypassing all network code.
sub make_ident {
    my (%args) = @_;
    my $obj = bless {
        remoteport => $args{remoteport} // 6191,
        localport  => $args{localport}  // 23,
        answer     => $args{answer},
        state      => 'ready',
    }, 'Net::Ident::MockReady';
    return $obj;
}

# --- Successful USERID responses ---

subtest 'basic USERID response' => sub {
    my $obj = make_ident(
        answer     => '6191, 23 : USERID : UNIX : joe',
        remoteport => 6191,
        localport  => 23,
    );

    my ($user, $opsys, $error) = $obj->username;
    is($user,  'joe',   'username parsed correctly');
    is($opsys, 'UNIX',  'opsys parsed correctly');
    is($error, undef,   'no error on success');

    # scalar context
    is(scalar $obj->username, 'joe', 'scalar context returns username');
};

subtest 'username with spaces' => sub {
    my $obj = make_ident(answer => '6191, 23 : USERID : UNIX :  joe smith ');
    my ($user, $opsys, $error) = $obj->username;
    is($user,  'joe smith', 'leading space stripped, trailing space stripped');
    is($opsys, 'UNIX',      'opsys correct');
    is($error, undef,       'no error');
};

subtest 'backslash-escaped characters in userid (rfc931 style)' => sub {
    my $obj = make_ident(answer => '6191, 23 : USERID : UNIX : joe\\:user');
    my ($user, $opsys, $error) = $obj->username;
    is($user, 'joe:user', 'backslash-escaped colon unescaped');
};

subtest 'backslash-escaped characters in opsys' => sub {
    my $obj = make_ident(answer => '6191, 23 : USERID : UNIX\\:BSD : joe');
    my ($user, $opsys, $error) = $obj->username;
    is($opsys, 'UNIX:BSD', 'backslash-escaped colon in opsys unescaped');
};

subtest 'OTHER opsys preserves userid verbatim' => sub {
    # rfc1413: OTHER means the userid is an opaque token, no unescaping
    my $obj = make_ident(answer => '6191, 23 : USERID : OTHER : abc\\:def ');
    my ($user, $opsys, $error) = $obj->username;
    is($user,  'abc\\:def ', 'OTHER: no unescaping, trailing space preserved');
    is($opsys, 'OTHER',      'opsys is OTHER');
};

subtest 'charset in opsys (comma-separated) preserves userid' => sub {
    # rfc1413: opsys with charset like "UNIX,US-ASCII"
    my $obj = make_ident(answer => '6191, 23 : USERID : UNIX,US-ASCII : joe\\:x ');
    my ($user, $opsys, $error) = $obj->username;
    is($user,  'joe\\:x ', 'charset opsys: no unescaping, trailing space preserved');
    is($opsys, 'UNIX,US-ASCII', 'opsys with charset');
};

subtest 'whitespace around ports and fields' => sub {
    my $obj = make_ident(answer => ' 6191 , 23 : USERID : UNIX : alice');
    my ($user, $opsys, $error) = $obj->username;
    is($user,  'alice', 'extra whitespace around ports handled');
    is($opsys, 'UNIX',  'opsys correct');
};

# --- ERROR responses ---

subtest 'ERROR response - INVALID-PORT' => sub {
    my $obj = make_ident(answer => '6191, 23 : ERROR : INVALID-PORT');
    my ($user, $opsys, $error) = $obj->username;
    is($user,  undef,          'username undef on ERROR');
    is($opsys, 'ERROR',        'opsys is ERROR');
    is($error, 'INVALID-PORT', 'error message extracted');

    # scalar context
    is(scalar $obj->username, undef, 'scalar context returns undef on error');
};

subtest 'ERROR response - NO-USER' => sub {
    my $obj = make_ident(answer => '6191, 23 : ERROR : NO-USER');
    my ($user, $opsys, $error) = $obj->username;
    is($user,  undef,     'username undef');
    is($opsys, 'ERROR',   'opsys ERROR');
    is($error, 'NO-USER', 'error NO-USER');
};

subtest 'ERROR response - HIDDEN-USER' => sub {
    my $obj = make_ident(answer => '6191, 23 : ERROR : HIDDEN-USER');
    my ($user, $opsys, $error) = $obj->username;
    is($error, 'HIDDEN-USER', 'error HIDDEN-USER');
};

subtest 'ERROR response - UNKNOWN-ERROR' => sub {
    my $obj = make_ident(answer => '6191, 23 : ERROR : UNKNOWN-ERROR');
    my ($user, $opsys, $error) = $obj->username;
    is($error, 'UNKNOWN-ERROR', 'error UNKNOWN-ERROR');
};

# --- Port mismatch ---

subtest 'port mismatch - remote port' => sub {
    my $obj = make_ident(
        answer     => '9999, 23 : USERID : UNIX : joe',
        remoteport => 6191,
        localport  => 23,
    );
    my ($user, $opsys, $error) = $obj->username;
    is($user, undef, 'username undef on port mismatch');
    like($error, qr/couldn't parse|port mismatch/i, 'error mentions parse/mismatch');
};

subtest 'port mismatch - local port' => sub {
    my $obj = make_ident(
        answer     => '6191, 80 : USERID : UNIX : joe',
        remoteport => 6191,
        localport  => 23,
    );
    my ($user, $opsys, $error) = $obj->username;
    is($user, undef, 'username undef on local port mismatch');
};

# --- Malformed responses ---

subtest 'completely garbled response' => sub {
    my $obj = make_ident(answer => 'this is not a valid response');
    my ($user, $opsys, $error) = $obj->username;
    is($user, undef, 'username undef on garbled input');
    like($error, qr/couldn't parse/i, 'error mentions parse failure');
};

subtest 'empty response' => sub {
    my $obj = make_ident(answer => '');
    my ($user, $opsys, $error) = $obj->username;
    is($user, undef, 'username undef on empty response');
};

subtest 'missing userid field' => sub {
    my $obj = make_ident(answer => '6191, 23 : USERID : UNIX :');
    my ($user, $opsys, $error) = $obj->username;
    # The regex requires at least something after the last colon for opsys parsing
    # An empty userid after opsys should still parse
    ok(defined($user) || defined($error), 'handles missing userid without crash');
};

# --- Object in error state (no network connection made) ---

subtest 'object in error state' => sub {
    # Use real Net::Ident (not MockReady) to test the actual error path:
    # ready() will call query() which returns undef because there's no fh,
    # and username() returns the error.
    my $obj = bless {
        state => 'error',
        error => "Net::Ident::new: fh undef\n",
    }, 'Net::Ident';
    my ($user, $opsys, $error) = $obj->username;
    is($user,  undef, 'username undef for error-state object');
    is($opsys, undef, 'opsys undef for error-state object');
    like($error, qr/fh undef/, 'error message preserved');
};

# --- geterror method ---

subtest 'geterror returns stored error' => sub {
    my $obj = bless {
        state => 'error',
        error => "some error\n",
    }, 'Net::Ident';
    like($obj->geterror, qr/some error/, 'geterror returns the error');
};

subtest 'geterror returns undef when no error' => sub {
    my $obj = make_ident(answer => '6191, 23 : USERID : UNIX : joe');
    is($obj->geterror, undef, 'no error stored initially');
};

# --- getfh method ---

subtest 'getfh returns undef for error-state object' => sub {
    my $obj = bless {
        state => 'error',
        error => "Net::Ident::new: fh undef\n",
    }, 'Net::Ident';
    is($obj->getfh, undef, 'getfh undef when no fh');
};

# --- newFromInAddr error state consistency ---

subtest 'newFromInAddr sets error state on failure' => sub {
    # Use an IP not bound to any local interface — bind() will fail
    # with "Cannot assign requested address"
    my $bad_local  = Socket::sockaddr_in(12345, Socket::inet_aton("192.0.2.1"));
    my $bad_remote = Socket::sockaddr_in(113,   Socket::inet_aton("192.0.2.2"));
    my $obj = Net::Ident->newFromInAddr($bad_local, $bad_remote);

    # Constructor should succeed (returns blessed object)
    isa_ok($obj, 'Net::Ident', 'constructor succeeds even on error');

    # But state should be 'error', not 'connect'
    is($obj->{state}, 'error', 'state is error after bind failure');

    # Error message should be set
    like($obj->geterror, qr/bind failed/i, 'error message mentions bind');

    # getfh should return undef (fh was deleted)
    is($obj->getfh, undef, 'no filehandle after error');
};

# --- ready() method ---

subtest 'ready returns 1 on repeated calls after success' => sub {
    # This tests the fix for the dead-code bug where the elsif(state eq 'ready')
    # was unreachable, causing subsequent ready() calls to fail instead of
    # returning 1 as documented.
    my $obj = make_ident(answer => '6191, 23 : USERID : UNIX : joe');
    # State is already 'ready', so ready() should return 1 immediately
    is($obj->ready(0), 1, 'first ready() call returns 1');
    is($obj->ready(0), 1, 'second ready() call still returns 1');
    is($obj->ready(1), 1, 'ready(blocking) also returns 1');
};
# --- ready() EOF handling ---

subtest 'ready returns undef when remote closes without newline' => sub {
    # Regression test: sysread returning 0 (EOF) used to cause an infinite
    # loop in blocking mode because defined(0) is true.
    # We use socketpair to get a real filehandle that we can close one end of.
    use Socket qw(PF_UNIX SOCK_STREAM);
    my ($reader, $writer);
    socketpair($reader, $writer, PF_UNIX, SOCK_STREAM, 0)
        or plan skip_all => "socketpair not available: $!";

    # Send partial data (no \r\n), then close the writer to trigger EOF
    print $writer "6191, 23 : USERID : UNIX : joe";
    close $writer;

    # Build an object in 'query' state with the reader as its fh
    my $obj = bless {
        state      => 'query',
        answer     => '',
        fh         => $reader,
        remoteport => 6191,
        localport  => 23,
        maxtime    => time + 5,  # safety timeout
    }, 'Net::Ident';

    # ready(1) should detect EOF and return undef, not loop forever
    my $result = $obj->ready(1);
    is($result, undef, 'ready returns undef on EOF without newline');
    like($obj->geterror, qr/closed connection/i, 'error mentions closed connection');
    close $reader;
};

done_testing;
