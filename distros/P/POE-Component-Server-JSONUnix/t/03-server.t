use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Socket qw(PF_UNIX SOCK_STREAM);
use IO::Socket::UNIX;

# If the runtime deps are missing, skip cleanly. This BEGIN block runs (and may
# exit via skip_all) *before* the "use POE" below is compiled, so the absence of
# POE never turns into a compile error.
BEGIN {
    unless ( eval { require POE; require JSON::MaybeXS; 1 } ) {
        plan skip_all =>
            'POE and JSON::MaybeXS are required for the live server test';
    }
}

plan skip_all => 'fork is not available on this platform'
    unless $Config{d_fork};
plan skip_all => 'Unix domain sockets are unavailable'
    unless eval { socket( my $s, PF_UNIX, SOCK_STREAM, 0 ) };

use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line Driver::SysRW);
use POE::Component::Server::JSONUnix;
use JSON::MaybeXS ();

my $dir  = tempdir( CLEANUP => 1 );
my $sock = "$dir/srv.sock";

my $pid = fork;
defined $pid or plan skip_all => "fork failed: $!";

# ---------------------------------------------------------------------------
# Child: run the server, then exit without touching Test::* state.
# ---------------------------------------------------------------------------
if ( $pid == 0 ) {
    my $server = POE::Component::Server::JSONUnix->spawn(
        socket_path => $sock,
        commands    => {
            echo => sub { my ( $s, $r, $c ) = @_; +{ echoed => $r->{args} } },
            add  => sub {
                my ( $s, $r, $c ) = @_;
                my $t = 0;
                $t += $_ for @{ $r->{args}{numbers} // [] };
                +{ sum => $t };
            },
            boom => sub { die "kaboom\n" },
            slow => sub {
                my ( $s, $r, $c ) = @_;
                $poe_kernel->post( helper => defer => $c );
                return;    # answered asynchronously
            },
        },
    );

    POE::Session->create(
        inline_states => {
            _start => sub { $_[KERNEL]->alias_set('helper') },
            defer  => sub {
                my ( $k, $ctx ) = @_[ KERNEL, ARG0 ];
                $k->delay_add( go => 0.05, $ctx );
            },
            go => sub { $_[ARG0]->respond_result( { deferred => 1 } ) },
        },
    );

    $poe_kernel->run;

    require POSIX;
    POSIX::_exit(0);    # skip END blocks so we never emit stray TAP
}

# ---------------------------------------------------------------------------
# Parent: connect as a blocking client and check request/response pairs.
# ---------------------------------------------------------------------------
my $client;
for ( 1 .. 100 ) {     # wait up to ~5s for the child to bind the socket
    $client = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $sock );
    last if $client;
    select undef, undef, undef, 0.05;
}

unless ( ok( $client, 'connected to the server' ) ) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
    done_testing();
    exit 0;
}
$client->autoflush(1);

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Send one request (hashref is encoded; a string is sent verbatim) and decode
# the single line of response.
my $round_trip = sub {
    my ($req) = @_;
    my $payload = ref $req ? $json->encode($req) : $req;
    print {$client} $payload, "\n";
    my $line = readline $client;
    return defined $line ? $json->decode($line) : undef;
};

subtest 'ping (built-in)' => sub {
    my $r = $round_trip->( { command => 'ping', id => 1 } );
    is( $r->{status}, 'ok', 'ok status' );
    is( $r->{id},     1,    'id echoed' );
    ok( $r->{result}{pong}, 'pong in result' );
};

subtest 'echo round-trips args' => sub {
    my $r = $round_trip->(
        { command => 'echo', id => 2, args => { x => 42, list => [ 1, 2 ] } } );
    is_deeply( $r->{result}{echoed}, { x => 42, list => [ 1, 2 ] },
        'args returned unchanged' );
};

subtest 'add sums numbers' => sub {
    my $r = $round_trip->(
        { command => 'add', id => 3, args => { numbers => [ 1, 2, 3, 4 ] } } );
    is( $r->{result}{sum}, 10, 'sum is correct' );
};

subtest 'commands lists everything' => sub {
    my $r = $round_trip->( { command => 'commands', id => 4 } );
    my %have = map { $_ => 1 } @{ $r->{result}{commands} };
    ok( $have{ping} && $have{commands} && $have{echo} && $have{add},
        'built-in and custom commands are listed' );
};

subtest 'unknown command errors' => sub {
    my $r = $round_trip->( { command => 'does_not_exist', id => 5 } );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/unknown command/, 'descriptive message' );
    is( $r->{id}, 5, 'id echoed on errors too' );
};

subtest 'a dying handler becomes an error response' => sub {
    my $r = $round_trip->( { command => 'boom', id => 6 } );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/kaboom/, 'die message surfaced' );
    unlike( $r->{error}, qr/ at .* line \d+/, 'file/line noise stripped' );
};

subtest 'asynchronous handler replies later' => sub {
    my $r = $round_trip->( { command => 'slow', id => 7 } );
    is( $r->{status}, 'ok', 'ok status' );
    ok( $r->{result}{deferred}, 'deferred result delivered' );
    is( $r->{id}, 7, 'id echoed' );
};

subtest 'malformed JSON errors without killing the server' => sub {
    my $r = $round_trip->('{ this is not valid json');
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/invalid JSON/, 'descriptive message' );
};

subtest 'missing command field errors' => sub {
    my $r = $round_trip->( { id => 9 } );
    is( $r->{status}, 'error', 'error status' );
    like( $r->{error}, qr/missing 'command'/, 'descriptive message' );
};

close $client;
kill 'TERM', $pid;
waitpid $pid, 0;

done_testing();
