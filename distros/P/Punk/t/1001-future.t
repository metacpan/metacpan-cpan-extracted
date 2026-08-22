#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Time::HiRes ();
use Scalar::Util ();
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# Punk::Future: a Future-compatible async result that runs on the Hyperman
# worker loop when one is live and blocks otherwise. This file drives the
# self-contained (off-loop) semantics in-process, the dispatcher awaiting a
# returned future, and - on a real Hyperman worker - the non-blocking path.

use Punk::Future;

# ---- settling and callbacks -------------------------------------------------
{
    my $f = Punk::Future->new;
    ok(!$f->is_ready, 'new future is pending');
    my (@ready, @done, @fail);
    $f->on_ready(sub { push @ready, $_[0]->state });
    $f->on_done(sub { push @done, @_ });
    $f->on_fail(sub { push @fail, @_ });
    $f->done(1, 2);
    ok($f->is_ready && $f->is_done, 'done makes it ready/done');
    is_deeply(\@done, [1, 2], 'on_done got the values');
    is("@ready", "1", 'on_ready fired with the done state');
    is_deeply(\@fail, [], 'on_fail did not fire');
    is_deeply([$f->get], [1, 2], 'get returns the values');

    my $late;
    $f->on_done(sub { $late = "@_" });
    is($late, "1 2", 'a callback on an already-done future fires at once');

    my $g = Punk::Future->new;
    $g->fail("boom\n");
    ok($g->is_failed, 'fail makes it failed');
    is($g->failure, "boom\n", 'failure is the message');
    eval { $g->get }; is($@, "boom\n", 'get rethrows the failure');
}

# ---- done_future / fail_future ----------------------------------------------
is_deeply([Punk::Future->done_future(4, 5)->get], [4, 5], 'done_future');
ok(Punk::Future->fail_future("x\n")->is_failed, 'fail_future');

# ---- then / else / catch / followed_by --------------------------------------
{
    my @log;
    my $f = Punk::Future->new;
    $f->then(sub { "got:$_[0]" })->on_done(sub { push @log, "then:@_" });
    $f->done(7);
    is($log[-1], "then:got:7", 'then maps the value');

    # a callback returning a future is adopted
    my ($h, $inner) = (Punk::Future->new, Punk::Future->new);
    $h->then(sub { $inner })->on_done(sub { push @log, "adopt:@_" });
    $h->done("x"); $inner->done("deep");
    is($log[-1], "adopt:deep", 'a returned future is adopted');

    # catch recovers a die; the chain continues
    my $d = Punk::Future->new;
    $d->then(sub { die "oops\n" })->catch(sub { "recovered" })
      ->on_done(sub { push @log, "recover:@_" });
    $d->done(1);
    is($log[-1], "recover:recovered", 'catch turns a die into the done branch');

    # else passes a success through untouched
    my $p = Punk::Future->new;
    $p->else(sub { "never" })->on_done(sub { push @log, "pass:@_" });
    $p->done(9);
    is($log[-1], "pass:9", 'else passes success through');

    # a plain then passes a failure through
    my $q = Punk::Future->new;
    $q->then(sub { "no" })->on_fail(sub { push @log, "qfail:@_" });
    $q->fail("bad");
    is($log[-1], "qfail:bad", 'then without a fail handler passes failure through');

    my $fb = Punk::Future->new;
    $fb->followed_by(sub { Punk::Future->done_future("fb:" . $_[0]->is_done) })
       ->on_done(sub { push @log, "fb:@_" });
    $fb->done;
    is($log[-1], "fb:fb:1", 'followed_by runs on any outcome with the future');
}

# ---- combinators ------------------------------------------------------------
{
    my @log;
    my ($a, $b, $cc) = map { Punk::Future->new } 1 .. 3;
    Punk::Future->needs_all($a, $b, $cc)->on_done(sub { push @log, "@_" });
    $b->done("B"); $a->done("A"); $cc->done("C");
    is($log[-1], "A B C", 'needs_all combines values in input order');

    my ($x, $y) = map { Punk::Future->new } 1 .. 2;
    my $fail;
    Punk::Future->needs_all($x, $y)->on_fail(sub { $fail = "@_" });
    $x->fail("nope");
    is($fail, "nope", 'needs_all fails as soon as one fails');

    my ($p, $q) = map { Punk::Future->new } 1 .. 2;
    my $any;
    Punk::Future->needs_any($p, $q)->on_done(sub { $any = "@_" });
    $p->fail("no"); $q->done("won");
    is($any, "won", 'needs_any is done on the first success');

    my ($w1, $w2) = map { Punk::Future->new } 1 .. 2;
    my $waited;
    Punk::Future->wait_all($w1, $w2)->on_done(sub { $waited = scalar @_ });
    $w1->fail("e"); $w2->done("ok");
    is($waited, 2, 'wait_all is done when all have settled, whatever the outcome');

    ok(Punk::Future->all()->is_done,   'empty needs_all is done');
    ok(Punk::Future->any()->is_failed, 'empty needs_any is failed');

    # wait_any: done as soon as ANY has settled, whatever the outcome. The one
    # combinator with no test until now, and the one where getting it wrong
    # looks most like getting it right - a failure settles it, where needs_any
    # would keep waiting for a success.
    my ($a1, $a2) = map { Punk::Future->new } 1 .. 2;
    my $first;
    Punk::Future->wait_any($a1, $a2)->on_done(sub { $first = scalar @_ });
    $a1->fail("e");
    is($first, 1,
        'wait_any settles on the FIRST settled future even when it failed - '
      . 'which is what makes it wait_any and not needs_any');
    ok(!$a2->is_ready, 'and does not wait for the other');

    # The six entry points are one XSUB with an ALIAS list, and the alias
    # index is mapped to the mode by arithmetic: ix 0-3 pass through, 4 and 5
    # remap onto NEEDS_ALL and NEEDS_ANY. Reorder either list and every name
    # still exists while two of them quietly do somebody else's job. Only the
    # empty-list case pinned that down before, which is the one case where the
    # mode barely matters.
    {
        my ($b1, $b2) = map { Punk::Future->new } 1 .. 2;
        my $all;
        Punk::Future->all($b1, $b2)->on_done(sub { $all = "@_" });
        $b1->done("one");
        ok(!defined $all, 'all() waits for every input, like needs_all');
        $b2->done("two");
        is($all, "one two", 'and combines them in input order');

        my ($c1, $c2) = map { Punk::Future->new } 1 .. 2;
        my $any2;
        Punk::Future->any($c1, $c2)->on_done(sub { $any2 = "@_" });
        $c1->fail("no");
        ok(!defined $any2, 'any() is not satisfied by a failure, like needs_any');
        $c2->done("yes");
        is($any2, "yes", 'and is done on the first success');
    }
}

# ---- timer / defer / cancel (block mode: a timer sleeps) --------------------
{
    my $t0 = Time::HiRes::time();
    my $t  = Punk::Future->timer(0.1);
    ok($t->is_done, 'off-loop timer settles');
    ok(Time::HiRes::time() - $t0 >= 0.09, 'and it waited');

    is_deeply([Punk::Future->defer(sub { "deferred" })->get], ["deferred"],
        'defer runs the callback and settles with its result');

    my $f = Punk::Future->new;
    my $child = $f->then(sub { "unreached" });
    $f->cancel;
    ok($f->is_cancelled && $child->is_cancelled,
        'cancel settles the future and propagates down the chain');
}

# ---- the dispatcher awaits a returned future --------------------------------
{
    package FApp;
    use Punk;
    get '/done'  => sub { Punk::Future->done_future({ ok => 1 }) };
    get '/dies'  => sub { Punk::Future->fail_future('boom') };
    get '/timer' => sub { my $c = shift;
        $c->timer(0.05)->then(sub { $c->json({ waited => 1 }) }) };
    package main;

    my $app = FApp->to_app;

    my $r = hit($app, path => '/done');
    is($r->[0], 200, 'blocking: a returned future is awaited inline');
    is(file_json_decode($r->[2][0])->{ok}, 1, 'and JSONified');

    my $r2 = hit($app, path => '/timer');
    is($r2->[0], 200, 'a timer->then future comes back as a finished triplet');
    is(file_json_decode($r2->[2][0])->{waited}, 1, 'with the resolved body');

    # nonblocking server: a Future comes back, resolving to the triplet
    my $f = hit($app, path => '/done', env => { 'psgi.nonblocking' => 1 });
    ok(Scalar::Util::blessed($f) && $f->can('get'),
        'nonblocking: a future is returned');
    is($f->get->[0], 200, 'that resolves to the finished triplet');

    # nonblocking AND streaming: the future rides inside the standard delayed
    # response instead - plain CODE, so Lint and friends pass it through
    my $cr = hit($app, path => '/done',
        env => { 'psgi.nonblocking' => 1, 'psgi.streaming' => 1 });
    is(ref $cr, 'CODE', 'nonblocking+streaming: a delayed response coderef');
    my @sent;
    $cr->(sub { push @sent, $_[0] });
    is(scalar @sent, 1, 'the responder was called once');
    is($sent[0][0], 200, '...with the finished triplet');
    is(file_json_decode($sent[0][2][0])->{ok}, 1, '...carrying the body');

    # and a failing future goes through on_error to the responder too
    my @err;
    hit($app, path => '/dies',
        env => { 'psgi.nonblocking' => 1, 'psgi.streaming' => 1 }
    )->(sub { push @err, $_[0] });
    is($err[0][0], 500, 'a failed future answers 500 through the responder');
}

# ---- through Plack::Middleware::Lint (what plackup -E development wraps) -----
SKIP: {
    eval { require Plack::Middleware::Lint; 1 }
        or skip 'Plack::Middleware::Lint required', 2;

    package LintApp;
    use Punk;
    get '/f' => sub { Punk::Future->done_future({ lint => 'clean' }) };
    package main;

    my $lint = Plack::Middleware::Lint->wrap(LintApp->to_app);
    my $body = '';
    open my $in, '<', \$body or die $!;
    my $env = {
        REQUEST_METHOD => 'GET', PATH_INFO => '/f', QUERY_STRING => '',
        SCRIPT_NAME => '', SERVER_NAME => 'localhost', SERVER_PORT => 80,
        SERVER_PROTOCOL => 'HTTP/1.1', HTTP_HOST => 'localhost',
        'psgi.version' => [1, 1], 'psgi.url_scheme' => 'http',
        'psgi.input' => $in, 'psgi.errors' => \*STDERR,
        'psgi.multithread' => 0, 'psgi.multiprocess' => 0,
        'psgi.run_once' => 0, 'psgi.streaming' => 1, 'psgi.nonblocking' => 1,
    };
    my $res = eval { $lint->($env) };
    is($@, '', 'an async response survives Lint');
    my @got;
    $res->(sub { push @got, $_[0]; return }) if ref $res eq 'CODE';
    is(file_json_decode($got[0][2][0])->{lint}, 'clean',
        '...and delivers the resolved body through the responder');
}

# ---- on a real Hyperman worker: non-blocking ---------------------------------
SKIP: {
    eval { require Hyperman; require Punk::WebSocket; 1 }
        or skip 'Hyperman required for the loop tests', 1;
    require IO::Socket::INET;
    skip 'Hyperman 0.11+ (a live loop) required', 1
        unless Punk::WebSocket::_hm_available();

    my $port = 25600 + ($$ % 300);
    my $host = "127.0.0.1:$port";
    my $pid  = fork // die "fork: $!";
    if (!$pid) {
        close STDERR;
        package LApp;
        use Punk;
        get '/slow' => sub { my $c = shift;
            $c->timer(0.4)->then(sub { $c->json({ slept => 1 }) }) };
        get '/fast' => sub { $_[0]->text('fast') };
        get '/all'  => sub { my $c = shift;
            Punk::Future->needs_all($c->timer(0.15), $c->timer(0.15))
                ->then(sub { $c->text('both') }) };
        package main;
        Hyperman->run(app => LApp->to_app, host => '127.0.0.1',
                      port => $port, workers => 1);
        exit 0;
    }
    for (1 .. 60) {
        my $s = IO::Socket::INET->new(PeerAddr => $host);
        last if $s;
        Time::HiRes::sleep(0.1);
    }
    my $get = sub {
        my ($p) = @_;
        my $s = IO::Socket::INET->new(PeerAddr => $host) or return;
        $s->autoflush(1);
        syswrite $s, "GET $p HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n";
        return $s;
    };
    my $slurp = sub {
        my ($s) = @_;
        my $b = '';
        eval { local $SIG{ALRM} = sub { die "to\n" }; alarm 6;
               while (sysread $s, my $c, 4096) { $b .= $c } alarm 0 };
        return $b;
    };
    my $t0   = Time::HiRes::time();
    my $slow = $get->('/slow');
    my $fast = $get->('/fast');
    my $fbody = $slurp->($fast); my $ft = Time::HiRes::time() - $t0;
    my $sbody = $slurp->($slow); my $st = Time::HiRes::time() - $t0;
    like($fbody, qr/fast/, 'fast route served');
    like($sbody, qr/slept/, 'slow route resolved its timer future');
    ok($ft < $st - 0.2,
        'the worker served /fast while /slow was pending (non-blocking)');
    like($slurp->($get->('/all')), qr/both/, 'needs_all resolves on the loop');
    kill 9, $pid; waitpid $pid, 0;
}

done_testing;
