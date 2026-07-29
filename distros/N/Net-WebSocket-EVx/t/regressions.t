use strict;
use warnings;
$SIG{PIPE} = 'IGNORE';
use Socket;
use POSIX ();
use Fcntl;
use Test::More;
use Devel::Peek (); # must be loaded at compile time: SvREFCNT has a \[$@%&*] prototype
use EV;
use Net::WebSocket::EVx;

# Regression tests for bugs fixed in 0.21, plus previously untested paths.

sub pair {
    socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
    $_->blocking(0) for $a, $b;
    return ($a, $b);
}

sub drain { # run the loop briefly so queued frames actually move
    my $timer = EV::timer(shift || 0.3, 0, sub { EV::break(EV::BREAK_ALL()) });
    EV::run;
}

sub server { my ($fh, %o) = @_; Net::WebSocket::EVx->new({fh => $fh, on_msg_recv => sub {}, on_close => sub {}, %o}) }
sub client { my ($fh, %o) = @_; Net::WebSocket::EVx->new({type => 'client', fh => $fh, on_msg_recv => sub {}, on_close => sub {}, %o}) }

sub first_frame { # bytes a server-mode object put on the wire (unmasked)
    my ($opts, $method, @args) = @_;
    my ($a, $b) = pair();
    my $ws = server($a, %$opts);
    $ws->$method(@args);
    drain(0.2);
    sysread($b, my $buf, 4096);
    return $buf // '';
}

subtest 'DESTROY is idempotent' => sub {
    my ($a, $b) = pair();
    my $ws = server($a);
    $ws->DESTROY;
    ok(eval { $ws->DESTROY; 1 }, 'explicit DESTROY twice does not crash') or diag $@;

    my ($c, $d) = pair();
    { my $ws2 = server($c); $ws2->DESTROY; }   # explicit, then again at scope exit
    pass('explicit DESTROY followed by GC does not crash');

    my ($e, $f) = pair();
    my $ws3 = server($e);
    $ws3->DESTROY;
    like(
        do { eval { $ws3->queue_msg('x') }; $@ },
        qr/already been destroyed|not initialized/,
        'methods on a destroyed object croak instead of touching freed memory',
    );
};

subtest 'the caller keeps ownership of the descriptor' => sub {
    my ($a, $b) = pair();
    my $fd = fileno $a;
    my $closed = 0;
    my $srv = server($a, on_close => sub { $closed = 1; EV::break(EV::BREAK_ALL()) });
    my $cli = client($b);
    $cli->close(1000);
    drain(1);
    ok($closed, 'close handshake completed');
    ok(defined fcntl($a, F_GETFD, 0), 'our filehandle is still open after on_close');

    # take the number the module used, then drop the handle: nothing may reclaim it twice
    undef $srv;
    undef $a;
    my $raw = POSIX::open('/dev/null', POSIX::O_RDONLY());
    ok(defined $raw, 'grabbed a raw descriptor');
    ok(POSIX::close($raw), 'raw descriptor closes cleanly - no double close') if defined $raw;
};

subtest 'unsent fragmented source callbacks are released' => sub {
    my $gen = sub { ('data') };   # never reaches EOF
    my $before = Devel::Peek::SvREFCNT($gen);
    {
        my ($a, $b) = pair();
        my $ws = server($a);
        $ws->stop_write;
        $ws->queue_fragmented($gen, 2);
        is(Devel::Peek::SvREFCNT($gen), $before + 1, 'queueing holds a reference');
    }
    is(Devel::Peek::SvREFCNT($gen), $before, 'destroying with the message unsent gives it back');
};

subtest 'a dying callback does not corrupt or leak the object' => sub {
    my $destroyed = 0;
    {
        my ($a, $b) = pair();
        my $srv = server($a, on_msg_recv => sub { die "boom\n" }, on_close => sub { $destroyed++ });
        my $cli = client($b);
        $cli->queue_msg('trigger');
        my $err = do { local $@; eval { drain(1); 1 } ? undef : $@ };
        is($err, "boom\n", 'the exception is rethrown out of EV::run');
    }
    is($destroyed, 1, 'the object is still reclaimed afterwards');

    my $waited = 0;
    {
        my ($a, $b) = pair();
        my $srv = server($a);
        my $cli = client($b, on_close => sub { $waited++ });
        $cli->queue_msg('x');
        $cli->wait(sub { die "waiter boom\n" });
        my $err = do { local $@; eval { drain(1); 1 } ? undef : $@ };
        is($err, "waiter boom\n", 'a dying wait() callback is rethrown too');
    }
    is($waited, 1, 'and does not leak the object (was a permanent refcount leak)');
};

subtest 'genmask must return exactly the requested length' => sub {
    my ($a, $b) = pair();
    my $ws = client($a, genmask => sub { "\xaa" x $_[0] });
    is($ws->queue_msg('AAAA'), 0, 'a correctly sized mask is accepted');
    drain(0.2);
    sysread($b, my $buf, 100);
    is(substr($buf, 2, 4), "\xaa\xaa\xaa\xaa", 'and is used verbatim');

    for my $case (['short', sub { "\x41" }], ['undef', sub { undef }]) {
        my ($label, $cb) = @$case;
        my ($c, $d) = pair();
        my $bad = client($c, genmask => $cb);
        eval { $bad->queue_msg('AAAA'); drain(0.2) };
        like($@, qr/genmask callback must return exactly/, "a $label mask is an error, not a silent stale/zero key");
    }
};

subtest 'the built-in mask generator is seeded' => sub {
    my $prog = 'use blib; use Socket; use EV; use Net::WebSocket::EVx;'
        . 'socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die;'
        . '$_->blocking(0) for $a,$b;'
        . 'my $w = Net::WebSocket::EVx->new({type=>"client",fh=>$a,on_msg_recv=>sub{},on_close=>sub{}});'
        . '$w->queue_msg("AAAA"); my $t = EV::timer 0.2,0,sub{EV::break(EV::BREAK_ALL())}; EV::run;'
        . 'sysread($b,my $f,100); print unpack "H8", substr($f,2,4);';
    my @masks = map { scalar `$^X -e '$prog' 2>/dev/null` } 1 .. 2;
    plan skip_all => 'could not run subprocesses' if grep { !length } @masks;
    isnt($masks[0], $masks[1], "two processes produce different mask keys ($masks[0] vs $masks[1])");
};

subtest 'constructor validates the descriptor' => sub {
    like(do { eval { Net::WebSocket::EVx->new({}) }; $@ }, qr/needs an open/, 'no fh and no fd croaks');
    like(do { eval { Net::WebSocket::EVx->new({fd => -1}) }; $@ }, qr/invalid file descriptor/, 'a negative fd croaks');
    open my $fh, '<', '/dev/null' or die $!;
    close $fh;
    like(do { eval { Net::WebSocket::EVx->new({fh => $fh}) }; $@ }, qr/not an open filehandle/,
        'a closed handle croaks instead of silently attaching to stdin');
    my ($a, $b) = pair();
    ok(eval { server($a); 1 }, 'a valid handle still works') or diag $@;
};

subtest 'rsv is configurable, default unchanged' => sub {
    my $rsv1 = sub { (ord(substr shift, 0, 1) & 0x40) ? 1 : 0 };
    is($rsv1->(first_frame({}, queue_msg_ex => 'hi')), 1, 'queue_msg_ex still defaults to RSV1');
    is($rsv1->(first_frame({rsv => WS_RSV_NONE}, queue_msg_ex => 'hi')), 0, 'rsv => WS_RSV_NONE clears it');
    is($rsv1->(first_frame({rsv => WS_RSV_NONE}, queue_msg_ex => 'hi', 1, WS_RSV1_BIT)), 1,
        'an explicit per-call rsv still wins');
    my $gen = do { my $n = 0; sub { $n++ ? ('', WS_FRAGMENTED_EOF) : ('chunk') } };
    is($rsv1->(first_frame({rsv => WS_RSV_NONE}, queue_fragmented_ex => $gen)), 0,
        'queue_fragmented_ex honours it as well');

    for my $case ([WS_RSV1_BIT, 1], [WS_RSV_NONE, 0]) {
        my ($allowed, $expect) = @$case;
        my ($a, $b) = pair();
        my $got = 0;
        my $srv = server($a, allowed_rsv => $allowed, on_msg_recv => sub { $got = 1 });
        my $cli = client($b);
        $cli->queue_msg_ex('payload', 2, WS_RSV1_BIT);
        drain(0.4);
        is($got, $expect, sprintf 'allowed_rsv => %d %s an incoming RSV1 message',
            $allowed, $expect ? 'accepts' : 'rejects');
    }
};

subtest 'a callback may drop the last reference to its own object' => sub {
    my %conns;
    my ($a, $b) = pair();
    $conns{srv} = server($a, on_msg_recv => sub { delete $conns{srv} });
    my $cli = client($b);
    $cli->queue_msg('hello');
    ok(eval { drain(0.5); 1 }, 'tearing the connection down from inside on_msg_recv is safe') or diag $@;
    ok(!exists $conns{srv}, 'and the object really was released');
};

subtest 'documented error behaviour' => sub {
    my ($a, $b) = pair();
    my $ws = server($a);
    is($ws->close(1000, 'x' x 122), 0, 'a 122 byte close reason is accepted');
    is($ws->queue_msg('nope'), -302, 'queueing after close returns WSLAY_ERR_NO_MORE_MSG');

    my ($c, $d) = pair();
    my $ws2 = server($c);
    eval { $ws2->close(1000, 'x' x 124) };
    like($@, qr/WSLAY_ERR_INVALID_ARGUMENT/, 'an over-long close reason croaks');
};

subtest 'ping is answered with a pong' => sub {
    my ($a, $b) = pair();
    my (@srv_opcodes, @cli_opcodes);
    my $srv = server($a, on_frame_recv_start => sub { push @srv_opcodes, $_[2] });
    my $cli = client($b, on_frame_recv_start => sub { push @cli_opcodes, $_[2] });
    is($srv->queue_msg('ping-payload', 0x9), 0, 'queue_msg accepts opcode 0x9');
    drain(0.5);
    ok((grep { $_ == 0x9 } @cli_opcodes), 'the peer received a ping');
    ok((grep { $_ == 0xa } @srv_opcodes), 'and wslay answered it with a pong');
};

subtest 'fragmented message aborted with WS_FRAGMENTED_ERROR' => sub {
    my ($a, $b) = pair();
    my $closed = 0;
    my $n = 0;
    my $gen = sub { $n++ ? ('', WS_FRAGMENTED_ERROR) : ('chunk') };
    my $before = Devel::Peek::SvREFCNT($gen);
    my $srv = server($a, on_close => sub { $closed = 1 });
    my $cli = client($b);
    $srv->queue_fragmented($gen, 2);
    drain(0.5);
    ok($closed, 'the connection is torn down');
    is(Devel::Peek::SvREFCNT($gen), $before, 'and the source callback is released');
};

subtest 'replacing the wait() callback' => sub {
    my ($a, $b) = pair();
    my $first_ran = 0;
    my $first = sub { $first_ran++ };
    my $before = Devel::Peek::SvREFCNT($first);
    my $second_ran = 0;
    my $srv = server($a);
    my $cli = client($b);
    $srv->queue_msg('x');
    $srv->wait($first);
    $srv->wait(sub { $second_ran++ });
    drain(0.5);
    is($first_ran, 0, 'the replaced callback does not fire');
    is($second_ran, 1, 'the replacement does');
    is(Devel::Peek::SvREFCNT($first), $before, 'and the replaced one is released');
};

subtest 'stop_read / start_read cycle' => sub {
    my ($a, $b) = pair();
    my $got = 0;
    my $srv = server($a, on_msg_recv => sub { $got++ });
    my $cli = client($b);
    $srv->stop_read;
    $cli->queue_msg('while stopped');
    drain(0.4);
    is($got, 0, 'nothing is read while reading is stopped');
    $srv->start_read;
    drain(0.4);
    is($got, 1, 'the buffered message arrives after start_read');
};

subtest 'messages with extended payload lengths' => sub {
    for my $size (200, 70_000) { # 16 bit and 64 bit length encodings
        my ($a, $b) = pair();
        my $got;
        my $srv = server($a, on_msg_recv => sub { $got = $_[2] });
        my $cli = client($b);
        $cli->queue_msg('x' x $size, 2);
        drain(2);
        is(length($got // ''), $size, "a $size byte message round-trips intact");
    }
};

subtest 'invalid UTF-8 in a text frame fails the connection' => sub {
    my ($a, $b) = pair();
    my ($delivered, $closed) = (0, 0);
    my $srv = server($a, on_msg_recv => sub { $delivered = 1 }, on_close => sub { $closed = 1 });
    my $payload = "\xff\xfe";
    my $mask = "\x01\x02\x03\x04";
    my $masked = join '', map { chr(ord(substr $payload, $_, 1) ^ ord(substr $mask, $_ % 4, 1)) } 0 .. length($payload) - 1;
    syswrite($b, chr(0x81) . chr(0x80 | length $payload) . $mask . $masked) or die "write: $!";
    drain(0.5);
    is($delivered, 0, 'the message never reaches on_msg_recv');
    is($closed, 1, 'the connection is closed instead');
};

subtest 'surviving destruction of the event loop' => sub {
    my $prog = 'use blib; use Socket; use EV; use Net::WebSocket::EVx;'
        . 'socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die;'
        . '$_->blocking(0) for $a,$b;'
        . 'my $w = Net::WebSocket::EVx->new({fh=>$a,on_msg_recv=>sub{},on_close=>sub{}});'
        . 'EV::default_destroy(); undef $w; print "ok";';
    my $out = `$^X -e '$prog' 2>/dev/null`;
    is($out, 'ok', 'destroying a websocket after EV::default_destroy() does not crash');
};

done_testing();
