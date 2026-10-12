#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use IO::Select;
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
        $ws->on(message => sub {
            my ($conn, $msg) = @_;
            # everyone but the sender: the usual chat broadcast
            return $room->broadcast("only:$1", $conn) if $msg =~ /^except:(.*)/;
            $room->broadcast("said:$msg");
        });
        $ws->on(close   => sub { $room->leave($_[0]) });
    };

    # A room of two, for measuring what a broadcast costs the worker that
    # only RECEIVES it from the bus.
    websocket '/pair' => sub {
        my ($c, $ws) = @_;
        my $room = Punk::WebSocket::Room->named('pair');
        $ws->on(open    => sub { $room->join($_[0]); $_[0]->send("worker:$$") });
        $ws->on(message => sub { $room->broadcast($_[1]) });
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
    my ($path) = @_;
    my $s = sock();
    my ($req, $key) = handshake_request(host => $host,
                                        path => $path // '/chat');
    syswrite $s, $req;
    my $hdr = read_headers($s);
    return $hdr =~ m{^HTTP/1\.1 101}i ? $s : undef;
}

# decode_ref returns a HASHREF, not a string - the same reader t/1011-ws-live.t
# uses, because writing a second one is how the two drift.
sub read_frame {
    my ($s, $timeout) = @_;
    my $buf = \${*$s}{ws_buf};
    $$buf //= '';
    my $f;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($timeout || 5);
        while (1) {
            $f = decode_ref($$buf);
            last if $f && ref $f;
            my $n = sysread $s, my $c, 4096;
            last unless $n;
            $$buf .= $c;
        }
        alarm 0;
    };
    alarm 0;
    return undef unless ref $f;
    substr $$buf, 0, $f->{consumed}, '';
    return $f;
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
           . "distinguish a working bus from a single-worker room", 6
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
        # one second of silence across all of them at once: the number of
        # clients depends on how the kernel spread them, and a second each
        # made this the slowest file in the suite on an unlucky run
        my $extra = () = IO::Select->new(@clients)->can_read(1);
        is($extra, 0,
            'and nobody heard it TWICE - the publishing worker does not also '
          . 'send locally, so there is one delivery path rather than two that '
          . 'can drift apart');

        # The same with the sender left out. `except` names a connection, and
        # a connection lives in one worker - so this used to be sent to that
        # worker's members alone, and the rest of the room heard nothing.
        for my $i (0, $#clients) {
            syswrite $clients[$i],
                encode_client(opcode => 1, payload => "except:from $i");
            my @heard = grep { my $f = read_frame($clients[$_], 5);
                               $f && ($f->{payload} // '') eq "only:from $i" }
                        grep { $_ != $i } 0 .. $#clients;
            is(scalar @heard, @clients - 1,
                "a broadcast that leaves out client $i reaches every other "
              . "client, on every worker")
                or diag sprintf 'heard by %d of %d others', scalar @heard,
                                @clients - 1;
            # one second of silence across all of them, the sender included
            my $sel = IO::Select->new(@clients);
            my @noisy = $sel->can_read(1);
            is(scalar @noisy, 0,
                '...and neither the sender nor anyone a second time hears it');
        }
    }
    note "connections spread over $spread worker(s) after $attempts attempts";

    close $_ for @clients;
}

# ---- what a broadcast costs the workers that receive it ----------------------
# The publishing worker fans out inside its own message handler. Every other
# worker is handed the frame by the event loop, in a callback with no
# temporaries frame around it - where the room name and the frame, made
# mortal, stayed allocated until the worker exited.
SKIP: {
    my $rss = sub {
        my ($w) = @_;
        my ($r) = (`ps -o rss= -p $w` // '') =~ /(\d+)/;
        return defined $r ? int($r / 1024) : undef;
    };
    my (%sock, $tries);
    while ($tries++ < 40 && keys %sock < 2) {
        my $c = ws_connect('/pair') or next;
        my $f = read_frame($c, 5);
        my ($w) = ($f && ($f->{payload} // '')) =~ /^worker:(\d+)/;
        if ($w && !$sock{$w}) { $sock{$w} = $c } else { close $c }
        Time::HiRes::sleep(0.05);
    }
    skip 'could not put two clients on two workers', 2 if keys %sock < 2;
    my ($pub, $rcv) = sort keys %sock;
    skip 'cannot read a worker\'s resident size here', 2
        unless defined $rss->($rcv);
    Time::HiRes::sleep(0.3);

    my $big = 'm' x 32_000;
    my $batch = sub {
        my ($tag) = @_;
        syswrite $sock{$pub}, encode_client(opcode => 1, payload => $big)
            for 1 .. 300;
        syswrite $sock{$pub}, encode_client(opcode => 1, payload => $tag);
        for my $w ($pub, $rcv) {            # both must read what they are sent
            while (my $f = read_frame($sock{$w}, 10)) {
                last if ($f->{payload} // '') eq $tag;
            }
        }
    };
    $batch->('warm');
    my $before = $rss->($rcv);
    $batch->("round$_") for 1 .. 4;
    my $grew = $rss->($rcv) - $before;
    ok(defined $before, 'the receiving worker was measured');
    cmp_ok($grew, '<', 15,
        "38 MB of broadcasts grew the worker that only received them by ${grew} MB");
    close $_ for values %sock;
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
