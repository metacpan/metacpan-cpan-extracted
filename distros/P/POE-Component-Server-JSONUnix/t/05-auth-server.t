use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Socket qw(PF_UNIX SOCK_STREAM);
use IO::Socket::UNIX;

BEGIN {
    unless ( eval { require POE; require JSON::MaybeXS; 1 } ) {
        plan skip_all =>
            'POE and JSON::MaybeXS are required for the live auth test';
    }
}

plan skip_all => 'fork is not available on this platform'
    unless $Config{d_fork};
plan skip_all => 'Unix domain sockets are unavailable'
    unless eval { socket( my $s, PF_UNIX, SOCK_STREAM, 0 ) };
plan skip_all => 'symlink is not available on this platform'
    unless $Config{d_symlink};

use POE;
use POE::Component::Server::JSONUnix;
use JSON::MaybeXS ();

my $dir      = tempdir( CLEANUP => 1 );
my $sock     = "$dir/auth.sock";
my $auth_tmp = "$dir/auth_files";   # server writes challenge files here
mkdir $auth_tmp or die "mkdir: $!";

my $pid = fork;
defined $pid or plan skip_all => "fork failed: $!";

# ---------------------------------------------------------------------------
# Child: server with auth_required and a whoami command.
# ---------------------------------------------------------------------------
if ( $pid == 0 ) {
    my $server = POE::Component::Server::JSONUnix->spawn(
        socket_path   => $sock,
        auth_temp_dir => $auth_tmp,
        auth_required => 1,
        commands      => {
            whoami => sub {
                my ( $s, $r, $ctx ) = @_;
                return {
                    uid      => $ctx->uid,
                    username => $ctx->username,
                    authed   => $ctx->authenticated ? 1 : 0,
                };
            },
        },
    );

    $poe_kernel->run;
    require POSIX;
    POSIX::_exit(0);
}

# ---------------------------------------------------------------------------
# Parent: blocking client helpers.
# ---------------------------------------------------------------------------
my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub connect_client {
    my $sock_ref = shift;
    for ( 1 .. 100 ) {
        my $c = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $$sock_ref );
        if ($c) { $c->autoflush(1); return $c }
        select undef, undef, undef, 0.05;
    }
    return;
}

sub round_trip {
    my ( $sock, $req ) = @_;
    my $payload = ref $req ? $json->encode($req) : $req;
    print {$sock} $payload, "\n";
    my $line = readline $sock;
    return defined $line ? $json->decode($line) : undef;
}

# Wait for the server to be ready.
my $first = connect_client( \$sock );
unless ( ok( $first, 'server came up' ) ) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
    done_testing();
    exit 0;
}
close $first;

# Identify who we are so we can verify the server echoes the right values.
my $my_uid      = $>;
my $my_username = ( getpwuid($my_uid) )[0] // '';

# ---------------------------------------------------------------------------
# Helpers for the two-step auth handshake.
# ---------------------------------------------------------------------------
sub do_auth_start {
    my ($c) = @_;
    return round_trip( $c, { command => 'auth_start' } );
}

sub do_auth_verify {
    my ( $c, $path ) = @_;
    return round_trip( $c, { command => 'auth_verify', args => { path => $path } } );
}

sub write_cookie {
    my ( $dir, $cookie ) = @_;
    my ( $fh, $path ) = tempfile( 'cookie_XXXXXX', DIR => $dir, UNLINK => 0 );
    print {$fh} $cookie;
    close $fh;
    return $path;
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

subtest 'auth_required blocks non-auth commands before authentication' => sub {
    my $c = connect_client( \$sock );
    my $r = round_trip( $c, { command => 'whoami', id => 1 } );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/authentication required/i, 'auth-required message' );
    is( $r->{id}, 1, 'id echoed' );
    close $c;
};

subtest 'auth_start is allowed before authentication' => sub {
    my $c = connect_client( \$sock );
    my $r = do_auth_start($c);
    is( $r->{status}, 'ok', 'ok status' );
    ok( defined $r->{result}{cookie},   'cookie present' );
    ok( length( $r->{result}{cookie} ) == 32, 'cookie is 32 hex chars' );
    like( $r->{result}{cookie}, qr/\A[0-9a-f]+\z/, 'cookie is lowercase hex' );
    is( $r->{result}{temp_dir}, $auth_tmp, 'temp_dir matches server config' );
    close $c;
};

subtest 'auth_verify without prior auth_start returns an error' => sub {
    my $c = connect_client( \$sock );
    my $r = do_auth_verify( $c, "$auth_tmp/no_such_file_$$" );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/auth_start/i, 'error mentions auth_start' );
    close $c;
};

subtest 'auth_verify with a nonexistent file returns an error' => sub {
    my $c      = connect_client( \$sock );
    my $start  = do_auth_start($c);
    my $cookie = $start->{result}{cookie};
    my $r      = do_auth_verify( $c, "$auth_tmp/no_such_file_$$" );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/not found/i, 'descriptive message' );

    # Challenge is consumed — a second auth_verify should also fail.
    my $r2 = do_auth_verify( $c, "$auth_tmp/no_such_file_$$" );
    is( $r2->{status}, 'error', 'second verify also errors' );
    like( $r2->{error}, qr/auth_start/i,
        'second verify says to call auth_start again' );
    close $c;
};

subtest 'auth_verify with a wrong cookie returns an error' => sub {
    my $c    = connect_client( \$sock );
    do_auth_start($c);    # establishes the challenge, discard result
    my $path = write_cookie( $auth_tmp, 'this-is-not-the-right-cookie' );
    my $r    = do_auth_verify( $c, $path );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/cookie mismatch/i, 'cookie mismatch message' );
    ok( !-e $path, 'temp file deleted by server even on mismatch' );
    close $c;
};

subtest 'auth_verify with a path outside auth_temp_dir returns an error' => sub {
    my $c      = connect_client( \$sock );
    my $start  = do_auth_start($c);
    my $cookie = $start->{result}{cookie};

    # Write a valid cookie file but in the wrong directory.
    my $wrong_dir = tempdir( CLEANUP => 1 );
    my $path      = write_cookie( $wrong_dir, $cookie );
    my $r         = do_auth_verify( $c, $path );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/directly inside/i, 'path-validation message' );

    # Challenge is NOT consumed by a path-validation failure, so we can retry.
    # Write to the correct dir this time — should now succeed.
    my $good_path = write_cookie( $auth_tmp, $cookie );
    my $r2        = do_auth_verify( $c, $good_path );
    is( $r2->{status}, 'ok', 'retry with correct path succeeds' );
    close $c;
    unlink $path;
};

subtest 'auth_verify with a relative path returns an error' => sub {
    my $c = connect_client( \$sock );
    do_auth_start($c);
    my $r = do_auth_verify( $c, 'relative/path/cookie' );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/absolute/i, 'absolute-path message' );
    close $c;
};

subtest 'auth_verify with a symlink returns an error' => sub {
    my $c      = connect_client( \$sock );
    my $start  = do_auth_start($c);
    my $cookie = $start->{result}{cookie};

    # Real file with the correct cookie, but outside auth_tmp.
    my $real = File::Spec->catfile( $dir, "real_cookie_$$" );
    open( my $fh, '>', $real ) or die "open: $!";
    print {$fh} $cookie;
    close $fh;

    # Symlink inside auth_tmp pointing at the real file.
    my $link = File::Spec->catfile( $auth_tmp, "link_$$" );
    symlink( $real, $link ) or die "symlink: $!";

    my $r = do_auth_verify( $c, $link );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/symbolic link/i, 'symlink rejection message' );
    ok( !-e $link && !-l $link, 'server removed the symlink' );
    close $c;
    unlink $real;
};

subtest 'successful auth returns current uid and username' => sub {
    my $c      = connect_client( \$sock );
    my $start  = do_auth_start($c);
    my $cookie = $start->{result}{cookie};
    my $path   = write_cookie( $auth_tmp, $cookie );
    my $r      = do_auth_verify( $c, $path );

    is( $r->{status},          'ok',         'ok status' );
    is( $r->{result}{uid},     $my_uid,      'uid matches effective uid of test process' );
    is( $r->{result}{username}, $my_username, 'username matches' );
    close $c;
};

subtest 'temp file is deleted by the server after successful verify' => sub {
    my $c      = connect_client( \$sock );
    my $start  = do_auth_start($c);
    my $cookie = $start->{result}{cookie};
    my $path   = write_cookie( $auth_tmp, $cookie );
    ok( -f $path, 'file exists before auth_verify' );
    do_auth_verify( $c, $path );
    ok( !-e $path, 'server deleted the file after verify' );
    close $c;
};

subtest 'commands succeed after authentication and ctx accessors are correct' => sub {
    my $c      = connect_client( \$sock );
    my $start  = do_auth_start($c);
    my $cookie = $start->{result}{cookie};
    my $path   = write_cookie( $auth_tmp, $cookie );
    do_auth_verify( $c, $path );

    my $r = round_trip( $c, { command => 'whoami', id => 99 } );
    is( $r->{status},            'ok',         'ok status' );
    is( $r->{id},                99,            'id echoed' );
    is( $r->{result}{uid},       $my_uid,       'ctx->uid correct' );
    is( $r->{result}{username},  $my_username,  'ctx->username correct' );
    is( $r->{result}{authed},    1,             'ctx->authenticated is true' );
    close $c;
};

subtest 'each connection has independent auth state' => sub {
    my $c1 = connect_client( \$sock );
    my $c2 = connect_client( \$sock );

    # Authenticate c1 but not c2.
    my $start  = do_auth_start($c1);
    my $cookie = $start->{result}{cookie};
    my $path   = write_cookie( $auth_tmp, $cookie );
    do_auth_verify( $c1, $path );

    my $r1 = round_trip( $c1, { command => 'whoami' } );
    is( $r1->{status}, 'ok', 'c1 (authed) gets ok' );

    my $r2 = round_trip( $c2, { command => 'whoami' } );
    is( $r2->{status}, 'error', 'c2 (not authed) gets error' );
    like( $r2->{error}, qr/authentication required/i, 'c2 blocked' );

    close $c1;
    close $c2;
};

# ---------------------------------------------------------------------------
kill 'TERM', $pid;
waitpid $pid, 0;

done_testing();
