use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir tempfile);
use Socket qw(PF_UNIX SOCK_STREAM);
use IO::Socket::UNIX;

BEGIN {
    unless ( eval { require POE; require JSON::MaybeXS; 1 } ) {
        plan skip_all =>
            'POE and JSON::MaybeXS are required for the live peercred test';
    }
}

plan skip_all => 'fork is not available on this platform'
    unless $Config{d_fork};
plan skip_all => 'Unix domain sockets are unavailable'
    unless eval { socket( my $s, PF_UNIX, SOCK_STREAM, 0 ) };

use POE;
use POE::Component::Server::JSONUnix;
use JSON::MaybeXS ();

# ---------------------------------------------------------------------------
# auth_method is validated synchronously in spawn(), no socket needed.
# ---------------------------------------------------------------------------
{
    my $err = do {
        local $@;
        eval {
            POE::Component::Server::JSONUnix->spawn(
                socket_path => '/nonexistent/should/not/matter.sock',
                auth_method => 'bogus',
            );
        };
        $@;
    };
    like( $err, qr/auth_method/, 'spawn rejects an invalid auth_method' );
}

my $dir      = tempdir( CLEANUP => 1 );
my $sock     = "$dir/peercred.sock";
my $auth_tmp = "$dir/auth_files";
mkdir $auth_tmp or die "mkdir: $!";

my $pid = fork;
defined $pid or plan skip_all => "fork failed: $!";

# ---------------------------------------------------------------------------
# Child: an auto-mode server (offers peercred where supported, cookie always).
# ---------------------------------------------------------------------------
if ( $pid == 0 ) {
    my $server = POE::Component::Server::JSONUnix->spawn(
        socket_path   => $sock,
        auth_temp_dir => $auth_tmp,
        auth_required => 1,
        auth_method   => 'auto',
        commands      => {
            whoami => sub {
                my ( $s, $r, $ctx ) = @_;
                return {
                    uid      => $ctx->uid,
                    username => $ctx->username,
                    peer_uid => $ctx->peer_uid,
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
    for ( 1 .. 100 ) {
        my $c = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $sock );
        if ($c) { $c->autoflush(1); return $c }
        select undef, undef, undef, 0.05;
    }
    return;
}

sub round_trip {
    my ( $c, $req ) = @_;
    print {$c} $json->encode($req), "\n";
    my $line = readline $c;
    return defined $line ? $json->decode($line) : undef;
}

my $first = connect_client();
unless ( ok( $first, 'server came up' ) ) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
    done_testing();
    exit 0;
}

# Does this platform actually provide peer credentials? auth_start advertises
# it when the kernel handed us the peer's uid at connect. If not, there is
# nothing to exercise here.
my $probe = round_trip( $first, { command => 'auth_start' } );
close $first;

unless ( $probe && $probe->{status} eq 'ok' && $probe->{result}{peercred} ) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
    plan skip_all => "kernel peer credentials are not available on $^O";
}

my $my_uid      = $>;
my $my_username = ( getpwuid($my_uid) )[0] // '';

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

subtest 'auth_start advertises peercred and still offers the cookie fallback' => sub {
    my $c = connect_client();
    my $r = round_trip( $c, { command => 'auth_start' } );
    is( $r->{status},             'ok', 'ok status' );
    is( $r->{result}{peercred},   1,    'peercred advertised' );
    ok( defined $r->{result}{cookie},   'cookie still present for fallback' );
    is( $r->{result}{temp_dir}, $auth_tmp, 'temp_dir present for fallback' );
    close $c;
};

subtest 'auth_verify with no path authenticates via the kernel' => sub {
    my $c = connect_client();
    round_trip( $c, { command => 'auth_start' } );
    my $r = round_trip( $c, { command => 'auth_verify', id => 3 } );
    is( $r->{status},           'ok',         'ok status' );
    is( $r->{id},               3,            'id echoed' );
    is( $r->{result}{uid},      $my_uid,      'uid is our effective uid' );
    is( $r->{result}{username}, $my_username, 'username matches' );
    close $c;
};

subtest 'auth_verify with no path works without a prior auth_start' => sub {
    # The cookie is irrelevant to the peercred path, so no handshake is needed.
    my $c = connect_client();
    my $r = round_trip( $c, { command => 'auth_verify' } );
    is( $r->{status},      'ok',    'ok status' );
    is( $r->{result}{uid}, $my_uid, 'uid is our effective uid' );
    close $c;
};

subtest 'commands succeed after peercred auth' => sub {
    my $c = connect_client();
    round_trip( $c, { command => 'auth_verify' } );
    my $r = round_trip( $c, { command => 'whoami', id => 9 } );
    is( $r->{status},           'ok',    'ok status' );
    is( $r->{id},               9,       'id echoed' );
    is( $r->{result}{uid},      $my_uid, 'ctx->uid correct' );
    is( $r->{result}{peer_uid}, $my_uid, 'ctx->peer_uid correct' );
    is( $r->{result}{authed},   1,       'ctx->authenticated is true' );
    close $c;
};

subtest 'the cookie-file path still works alongside peercred' => sub {
    my $c      = connect_client();
    my $start  = round_trip( $c, { command => 'auth_start' } );
    my $cookie = $start->{result}{cookie};

    my ( $fh, $path ) = tempfile( 'cookie_XXXXXX', DIR => $auth_tmp, UNLINK => 0 );
    print {$fh} $cookie;
    close $fh;

    my $r = round_trip( $c, { command => 'auth_verify', args => { path => $path } } );
    is( $r->{status},      'ok',    'cookie path still authenticates' );
    is( $r->{result}{uid}, $my_uid, 'uid matches' );
    ok( !-e $path, 'server unlinked the cookie file' );
    close $c;
};

subtest 'peercred auth is per-connection' => sub {
    my $c1 = connect_client();
    my $c2 = connect_client();

    round_trip( $c1, { command => 'auth_verify' } );    # authenticate c1 only

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
