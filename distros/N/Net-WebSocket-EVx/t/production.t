use strict;
use warnings;
use Socket;
use POSIX ();
use Devel::Peek ();
use Test::More;
use EV;
use Net::WebSocket::EVx;

sub pair {
    socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    $_->blocking(0) for $a, $b;
    return ($a, $b);
}

sub ws { my ($fh, %opts) = @_; Net::WebSocket::EVx->new({fh => $fh, %opts}) }

sub drain {
    EV::now_update();
    my $timer = EV::timer 0.1, 0, sub { EV::break(EV::BREAK_ALL()) };
    EV::run;
}

subtest 'queued callbacks keep their original values' => sub {
    for my $method (qw(queue_fragmented queue_fragmented_ex)) {
        my ($a, $b) = pair();
        my $got;
        my $srv = ws($a, rsv => WS_RSV_NONE);
        my $cli = ws($b, type => 'client', on_msg_recv => sub { $got = $_[2] });
        $srv->stop_write;
        my $cb = sub { ('original', WS_FRAGMENTED_EOF) };
        $srv->$method($cb);
        $cb = sub { ('replacement', WS_FRAGMENTED_EOF) };
        $srv->start_write;
        drain();
        is($got, 'original', "$method owns a callback value");
    }

    my ($a, $b) = pair();
    my ($first, $second) = (0, 0);
    my $srv = ws($a);
    $srv->stop_write;
    $srv->queue_msg('x');
    my $cb = sub { $first++ };
    $srv->wait($cb);
    $cb = sub { $second++ };
    $srv->start_write;
    drain();
    is($first, 1, 'wait owns the registered callback');
    is($second, 0, 'reassigning its variable does not replace it');

    $srv->wait(sub { $srv->wait(sub { $first++ }) });
    is($first, 2, 'a waiter registered by another waiter fires on an empty queue');
};

subtest 'wait callbacks can change IO state' => sub {
    my ($a, $b) = pair();
    my $got = 0;
    my $srv = ws($a, on_msg_recv => sub { $got++ });
    my $cli = ws($b, type => 'client');
    $srv->queue_msg('trigger');
    $srv->wait(sub { $srv->stop_read });
    drain();
    $cli->queue_msg('paused');
    drain();
    is($got, 0, 'stop_read from wait remains in effect');
    $srv->start_read;
    drain();
    is($got, 1, 'start_read delivers the pending message');

    $srv->queue_msg('trigger');
    $srv->wait(sub { $srv->stop });
    drain();
    $cli->queue_msg('stopped');
    drain();
    is($got, 1, 'stop from wait remains in effect');
    $srv->start;
    drain();
    is($got, 2, 'start resumes both directions');
};

subtest 'shutdown updates watchers immediately' => sub {
    my ($a, $b) = pair();
    my $closed = 0;
    my $srv = ws($a, on_close => sub { $closed++ });
    $srv->shutdown_read;
    syswrite($b, 'data') or die "write: $!";
    my $before = EV::iteration();
    drain();
    cmp_ok(EV::iteration() - $before, '<', 50, 'shutdown_read does not spin on a readable socket');
    is($srv->queue_msg('still writable'), 0, 'shutdown_read leaves the write side usable');
    drain();
    sysread($b, my $frame, 100);
    like($frame, qr/still writable/, 'the write side sends after shutdown_read');
    $srv->shutdown_write;
    is($closed, 1, 'shutting down both directions releases the connection');

    my ($c, $d) = pair();
    my $cli = ws($d, type => 'client');
    my $recv = 0;
    my $other;
    $other = ws($c, on_msg_recv => sub {
        $recv++;
        $other->shutdown_read;
        $other->shutdown_write;
    });
    $cli->queue_msg('shutdown in receive');
    drain();
    is($recv, 1, 'shutdown from a receive callback is safe');
    delete $other->{on_msg_recv};
};

subtest 'close completes the peer handshake' => sub {
    my ($a, $b) = pair();
    my (@codes, @messages);
    my $srv = ws($a, on_close => sub { push @codes, $_[0] }, on_msg_recv => sub { push @messages, $_[2] });
    my $cli = ws($b, type => 'client', on_close => sub { push @codes, $_[0] });
    $cli->close(1000, 'done');
    drain();
    is_deeply(\@codes, [1000, 1000], 'both endpoints receive the normal close status');
    is_deeply(\@messages, [], 'close frames are not delivered as messages');
};

subtest 'connection failure releases queued callbacks' => sub {
    my ($a, $b) = pair();
    my $source = sub { ('x', WS_FRAGMENTED_EOF) };
    my $waiter = sub { fail('a failed send must not run its waiter') };
    my $source_refs = Devel::Peek::SvREFCNT(&$source);
    my $waiter_refs = Devel::Peek::SvREFCNT(&$waiter);
    my $closed = 0;
    my $srv = ws($a, on_close => sub { $closed++ });
    $srv->stop_write;
    $srv->queue_fragmented($source);
    $srv->wait($waiter);
    close $b;
    drain();
    is($closed, 1, 'EOF closes the connection');
    is(Devel::Peek::SvREFCNT(&$source), $source_refs, 'an unsent source is released while the object is retained');
    is(Devel::Peek::SvREFCNT(&$waiter), $waiter_refs, 'an unsent waiter is released while the object is retained');
};

subtest 'a disconnected peer cannot terminate the process' => sub {
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $SIG{PIPE} = 'DEFAULT';
        my ($a, $b) = pair();
        my $closed = 0;
        my $srv = ws($a, on_close => sub { $closed++ });
        $srv->stop_read;
        close $b;
        $srv->queue_msg('peer is gone');
        drain();
        POSIX::_exit($closed == 1 ? 0 : 1);
    }
    waitpid($pid, 0);
    is($?, 0, 'send failure closes the connection without SIGPIPE');
};

subtest 'a pending advisory exception does not run the waiter' => sub {
    my ($a, $b) = pair();
    my ($waited, $closed) = (0, 0);
    my $srv = ws($a, on_msg_recv => sub { die "receive failed\n" }, on_close => sub { $closed++ });
    my $cli = ws($b, type => 'client');
    $srv->stop_write;
    $srv->queue_msg('reply');
    $srv->wait(sub { $waited++ });
    $cli->queue_msg('trigger');
    eval { drain() };
    is($@, "receive failed\n", 'the original exception is rethrown');
    is($waited, 0, 'the waiter has not run during error handling');
    is($closed, 0, 'an advisory exception keeps the connection alive');
    $srv->start_write;
    drain();
    is($waited, 1, 'normal queue draining still works after the exception');
};

subtest 'advisory exceptions preserve a pending client write' => sub {
    for my $callback (qw(on_frame_recv_start on_frame_recv_chunk on_frame_recv_end on_msg_recv)) {
        my ($a, $b) = pair();
        my $closed = 0;
        my $cli = ws($a, type => 'client', $callback => sub { die "$callback failed\n" },
            on_close => sub { $closed++ });
        syswrite($b, "\x81\x01x") or die "write: $!";
        $cli->queue_msg('pending');
        eval { drain() };
        is($@, "$callback failed\n", "$callback exception is rethrown");
        is($closed, 0, "$callback failure leaves the connection alive");
        delete $cli->{$callback};
        drain();
        my $n = sysread($b, my $frame, 100);
        ok($n && $n >= 13, "$callback does not lose the queued send");
    }
};

subtest 'default client masks survive entropy buffer refills' => sub {
    my ($a, $b) = pair();
    my @got;
    my $srv = ws($a, on_msg_recv => sub { push @got, $_[2] });
    my $cli = ws($b, type => 'client');
    $cli->queue_msg("message $_") for 1 .. 600;
    drain();
    is_deeply(\@got, [map { "message $_" } 1 .. 600], 'all payloads are correctly masked across refills');
};

subtest 'empty and unbuffered messages contain defined strings' => sub {
    for my $buffering (0, 1) {
        my ($a, $b) = pair();
        my @got;
        my $srv = ws($a, buffering => $buffering, on_msg_recv => sub { push @got, [$_[1], $_[2]] });
        my $cli = ws($b, type => 'client');
        $cli->queue_msg('', 1);
        $cli->queue_msg('', 2);
        $cli->queue_msg('data', 2);
        $cli->queue_msg('ping', 9);
        drain();
        is_deeply([grep { $_->[0] < 8 } @got], [[1, ''], [2, ''], [2, $buffering ? 'data' : '']],
            "buffering=$buffering preserves empty strings");
        is_deeply([grep { $_->[0] == 9 } @got], [[9, 'ping']],
            "buffering=$buffering preserves control payloads");
    }
};

done_testing();
