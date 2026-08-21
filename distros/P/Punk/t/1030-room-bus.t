#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use PunkWSRef qw(encode_client decode_ref handshake_request);

# THE BUG THIS EXISTS TO FIX.
#
# Punk::WebSocket::Room said it in its own documentation: a room is per worker,
# so under `workers => 4` a broadcast reached roughly a quarter of the people
# in it. The call succeeded, the return value was a plausible number, and
# nobody was told.
#
# So this runs a real server with SEVERAL workers, connects several clients -
# which land on different workers - and has one of them say something. Before
# the bus, only the clients that happened to share a worker with the speaker
# heard it. That is not a property one process can have, which is why this
# test needs a pool and cannot be faked.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman required for these tests';
    eval { require Punk::WebSocket; 1 }
        or plan skip_all => 'Punk::WebSocket unavailable';
    plan skip_all => 'Hyperman 0.11+ (the detach ABI) required'
        unless Punk::WebSocket::_hm_available();
}
plan skip_all => 'this Hyperman has no message bus (needs hm_abi v5)'
    unless Hyperman->can('bus_init');
plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

my $WORKERS = $ENV{RB_WORKERS} // 3;
my $CLIENTS = 6;              # two per worker, give or take the kernel

my $port = 25700 + ($$ % 200);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {

    require Punk::WebSocket::Room;

    package ChatApp;
    use Punk;

    websocket '/chat' => sub {
        my ($c, $ws) = @_;
        my $room = Punk::WebSocket::Room->named('lobby');
        $ws->on(open    => sub {
            $room->join($_[0]);
            # tell this client which worker it landed on, so the test can
            # prove the connections really spread across the pool
            $_[0]->send("worker:$$");
        });
        $ws->on(message => sub { $room->broadcast("said:$_[1]") });
        $ws->on(close   => sub { $room->leave($_[0]) });
    };

    # so a client can find out which worker served it
    get '/whoami' => sub { $_[0]->text("$$") };

    package main;
    Hyperman->run(app => ChatApp->to_app, host => '127.0.0.1',
                  port => $port, workers => $WORKERS);
    exit 0;
}

for (1 .. 80) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub sock {
    my $s = IO::Socket::INET->new(PeerAddr => $host) or die "connect: $!";
    $s->autoflush(1);
    return $s;
}

sub read_headers {
    my ($s) = @_;
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (sysread $s, my $c, 1) {
            $buf .= $c;
            last if $buf =~ /\r\n\r\n\z/;
        }
        alarm 0;
    };
    return $buf;
}

sub ws_connect {
    my $s = sock();
    my ($req, $key) = handshake_request(host => $host, path => '/chat');
    syswrite $s, $req;
    my $hdr = read_headers($s);
    return $hdr =~ m{^HTTP/1\.1 101}i ? $s : undef;
}

# decode_ref returns a HASHREF, not a string - the same reader t/1011-ws-live.t
# uses, because writing a second one is how the two drift.
sub read_frame {
    my ($s, $timeout) = @_;
    my $buf = '';
    my $f;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($timeout || 5);
        while (1) {
            $f = decode_ref($buf);
            last if $f && ref $f;
            my $n = sysread $s, my $c, 4096;
            last unless $n;
            $buf .= $c;
        }
        alarm 0;
    };
    alarm 0;
    return ref $f ? $f : undef;
}

# ---- the assertion that used to fail ----------------------------------------
{
    # Connect until the connections actually SPAN workers.
    #
    # With a shared listener whichever worker reaches accept() first can take
    # a whole burst, so simply opening six sockets often lands them all on one
    # - and then the old per-worker room would satisfy every assertion below
    # while fixing nothing. So this keeps connecting, with a pause to let
    # another worker win the race, until it has members on at least two.
    my (@clients, %worker_of);
    my $attempts = 0;
    while ($attempts++ < 40) {
        my $c = ws_connect() or next;
        my $f = read_frame($c, 5);
        if ($f && ($f->{payload} // '') =~ /^worker:(\d+)/) {
            push @clients, $c;
            $worker_of{$1}++;
        }
        else { close $c; next }
        last if @clients >= $CLIENTS && keys %worker_of > 1;
        Time::HiRes::sleep(0.05);      # let a different worker take the next
    }

    cmp_ok(scalar @clients, '>=', 2, 'several clients connected')
        or BAIL_OUT('could not connect');

    my $spread = keys %worker_of;
    SKIP: {
        skip "every connection landed on one worker after $attempts attempts; "
           . "this machine will not spread them, so nothing here could "
           . "distinguish a working bus from a single-worker room", 2
            if $spread < 2;

        Time::HiRes::sleep(0.3);      # every on_open has run and joined

        # one client says something; every client should hear it
        syswrite $clients[0],
            encode_client(opcode => 1, payload => 'hello everyone');

        my @heard = map { read_frame($_, 5) } @clients;
        my $n = grep { $_ && ($_->{payload} // '') eq 'said:hello everyone' }
                     @heard;

        is($n, scalar @clients,
            'EVERY client heard the broadcast, and the connections spanned '
          . "$spread workers - which is exactly what a per-worker room could "
          . 'not do')
            or diag sprintf 'heard %d of %d across %d workers',
                            $n, scalar @clients, $spread;

        # nobody heard it twice - the origin worker must not send locally AND
        # deliver from the bus
        my $extra = 0;
        for my $c (@clients) {
            my $again = read_frame($c, 1);
            $extra++ if defined $again;
        }
        is($extra, 0,
            'and nobody heard it TWICE - the publishing worker does not also '
          . 'send locally, so there is one delivery path rather than two that '
          . 'can drift apart');
    }
    note "connections spread over $spread worker(s) after $attempts attempts";

    close $_ for @clients;
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
