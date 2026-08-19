#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# `hook before_request`: the phase that runs BEFORE routing, on the same
# context the handler later gets.
#
# The two tests that matter are ordering and threading. Everything else is
# contract coverage inherited from before_dispatch, which this phase reuses
# wholesale (pd_run_chain + punk_finish_c), so a short-circuit, a die and a
# returned Future behave identically by construction rather than by copy.

# ---- 1. ordering: where the phase sits in the request ----------------------
{
    package OrderApp;
    use Punk;
    our @seen;
    session secret => 'order-key';
    csrf;
    hook before_request  => sub { push @seen, 'before_request';  return };
    hook before_dispatch => sub { push @seen, 'before_dispatch'; return };
    hook after_dispatch  => sub { push @seen, 'after_dispatch';  return };
    my $guarded = under '/g' => sub { push @seen, 'guard'; return };
    $guarded->get('/hit' => sub { push @seen, 'handler'; $_[0]->text('ok') });
    package main;

    @OrderApp::seen = ();
    my $r = hit(OrderApp->to_app, path => '/g/hit');
    is($r->[0], 200, 'the request is served');
    is_deeply(\@OrderApp::seen,
        [qw(before_request before_dispatch guard handler after_dispatch)],
        'before_request runs first, ahead of before_dispatch and the guard');
}

# ---- 1b. the price of being first, asserted rather than only documented ----
# The hook runs for requests csrf refuses and for requests over max_body.
# For a span that is the point - a refused request is still a request - and
# for work done on the client's behalf it is why before_dispatch still exists.
{
    package RefusedApp;
    use Punk;
    our @seen;
    session secret => 'refused-key';
    csrf;
    hook before_request  => sub { push @seen, 'before_request';  return };
    hook before_dispatch => sub { push @seen, 'before_dispatch'; return };
    post '/form' => sub { push @seen, 'handler'; $_[0]->text('ok') };
    post '/big'  => { cb => sub { push @seen, 'handler'; $_[0]->text('ok') },
                      max_body => 10 };
    package main;

    my $app = RefusedApp->to_app;

    @RefusedApp::seen = ();
    my $r = hit($app, method => 'POST', path => '/form', body => '{"a":1}');
    is($r->[0], 403, 'csrf refuses a POST with no token');
    is_deeply(\@RefusedApp::seen, ['before_request'],
        'before_request had already run; csrf stopped before_dispatch');

    @RefusedApp::seen = ();
    my $big = hit($app, method => 'POST', path => '/big',
                  body => '{"padding":"way over the ceiling"}');
    is($big->[0], 413, 'an oversize body is refused');
    is($RefusedApp::seen[0], 'before_request',
        'and before_request ran ahead of the max_body ceiling too');
    ok(!(grep { $_ eq 'handler' } @RefusedApp::seen), 'the handler did not');
}

# ---- 2. threading: ONE context, from the hook to the handler ---------------
# This is the test that fails if a second context gets built after routing,
# and the reason the phase is not a two-line patch.
{
    package ThreadApp;
    use Punk;
    our ($from_handler, $from_after);
    hook before_request => sub { $_[0]->stash->{t0} = 'stamped'; return };
    hook after_dispatch => sub {
        $from_after = $_[0]->stash->{t0}; return };
    get '/x' => sub {
        my ($c) = @_;
        $from_handler = $c->stash->{t0};
        $c->text('ok');
    };
    package main;

    my $r = hit(ThreadApp->to_app, path => '/x');
    is($r->[0], 200, 'served');
    is($ThreadApp::from_handler, 'stamped',
        'a stash written before routing survives into the handler');
    is($ThreadApp::from_after, 'stamped', 'and into after_dispatch');
}

# ---- 3-6. the phases before_dispatch never reaches -------------------------
{
    package ReachApp;
    use Punk;
    our @paths;
    hook before_request  => sub { push @paths, 'req:' . $_[0]->req->path; return };
    hook before_dispatch => sub { push @paths, 'disp'; return };
    get '/only' => sub { $_[0]->text('ok') };
    mount '/psgi' => sub {
        [200, ['Content-Type' => 'text/plain', 'Content-Length' => 6], ['mount!']]
    };
    static '/files' => "$FindBin::Bin/test/docs";
    package main;

    my $app = ReachApp->to_app;

    @ReachApp::paths = ();
    is(hit($app, path => '/nope')->[0], 404, 'a 404 is still a 404');
    is_deeply(\@ReachApp::paths, ['req:/nope'],
        'before_request runs on a 404, where before_dispatch never does');

    @ReachApp::paths = ();
    is(hit($app, method => 'POST', path => '/only')->[0], 405, 'a 405 is a 405');
    is_deeply(\@ReachApp::paths, ['req:/only'], 'and it runs on a 405');

    @ReachApp::paths = ();
    my $m = hit($app, path => '/psgi/thing');
    is($m->[0], 200, 'the mounted PSGI app still answers');
    is($m->[2][0], 'mount!', 'with its own body');
    is_deeply(\@ReachApp::paths, ['req:/psgi/thing'], 'and the hook saw it');

    @ReachApp::paths = ();
    hit($app, path => '/files/nothing.css');
    is_deeply(\@ReachApp::paths, ['req:/files/nothing.css'],
        'a static mount reaches it too');
}

# ---- 7. an API mount operation, and match by the time it dispatches --------
{
    package ApiReqApp;
    use Punk;
    our ($in_hook_op, $in_op_id);
    hook before_request => sub {
        $in_hook_op = $_[0]->match->{operation}; return };
    api {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1' },
        paths   => { '/ping' => { get => {
            operationId => 'ping',
            responses   => { 200 => { description => 'ok' } } } } },
    } => { handlers => {
        ping => sub {
            my ($c) = @_;
            $in_op_id = $c->match->{operation};
            return { ok => 1 };
        },
    } };
    package main;

    my $r = hit(ApiReqApp->to_app, path => '/ping');
    is($r->[0], 200, 'the operation runs');
    is($ApiReqApp::in_op_id, 'ping',
        '$c->match is populated by the time the operation does');
    is($ApiReqApp::in_hook_op, undef, 'but was not yet inside the hook');
}

# ---- 8. $c->match inside the hook is usable, not a croak ------------------
{
    package MatchApp;
    use Punk;
    our ($kind, $caps, $param);
    hook before_request => sub {
        my ($c) = @_;
        $kind  = ref $c->match;
        $caps  = $c->match->{captures};
        $param = $c->param('nope');
        return;
    };
    get '/m/:id' => sub { $_[0]->text('ok') };
    package main;

    is(hit(MatchApp->to_app, path => '/m/7')->[0], 200, 'served');
    is($MatchApp::kind, 'HASH', '$c->match is a hashref inside the hook');
    is_deeply($MatchApp::caps, {}, 'with empty captures');
    is($MatchApp::param, undef, 'and $c->param just misses, it does not croak');
}

# ---- 9. a reference return short-circuits, after_dispatch still runs -------
{
    package ShortApp;
    use Punk;
    our $after = 0;
    our $handler_ran = 0;
    hook before_request => sub { $_[0]->text('short', 202) };
    hook after_dispatch => sub { $after++; return };
    get '/never' => sub { $handler_ran++; $_[0]->text('handler') };
    package main;

    my $r = hit(ShortApp->to_app, path => '/never');
    is($r->[0], 202, 'the hook response is the response');
    is($r->[2][0], 'short', 'with its body');
    is($ShortApp::handler_ran, 0, 'the handler never ran');
    is($ShortApp::after, 1, 'after_dispatch still ran on it');
}

# ---- 10. a die goes through on_error --------------------------------------
{
    package DieApp;
    use Punk;
    hook before_request => sub { die "boom\n" };
    on_error sub { my ($c, $e) = @_; chomp(my $m = $e); $c->text("caught:$m", 500) };
    get '/x' => sub { $_[0]->text('ok') };
    package main;

    my $r = hit(DieApp->to_app, path => '/x');
    is($r->[0], 500, 'a die is a 500');
    is($r->[2][0], 'caught:boom', 'through the app on_error');
}

# ---- 11. a returned Future is awaited -------------------------------------
{
    package FutureApp;
    use Punk;
    hook before_request => sub {
        my ($c) = @_;
        my $f = Punk::Future->new;
        $f->done($c->text('from-future', 201));
        return $f;
    };
    get '/x' => sub { $_[0]->text('handler') };
    package main;

    my $r = hit(FutureApp->to_app, path => '/x');
    is($r->[0], 201, 'a returned Future is awaited');
    is($r->[2][0], 'from-future', 'and its value is the response');
}

# ---- 12. $c->log works in the hook (it needs PCX_APP, which ps_ctx sets) ---
{
    package LogApp;
    use Punk;
    our $logged = 0;
    logging level => 'debug', to => sub { $logged++ };
    hook before_request => sub { $_[0]->log->info('in the hook'); return };
    get '/x' => sub { $_[0]->text('ok') };
    package main;

    is(hit(LogApp->to_app, path => '/x')->[0], 200, 'served');
    ok($LogApp::logged, '$c->log->info works inside the hook');
}

# ---- 13. two hooks chain, and the first reference return wins --------------
{
    package ChainApp;
    use Punk;
    our @ran;
    hook before_request => sub { push @ran, 'one'; return };
    hook before_request => sub { push @ran, 'two'; $_[0]->text('two wins') };
    hook before_request => sub { push @ran, 'three'; return };
    get '/x' => sub { push @ran, 'handler'; $_[0]->text('ok') };
    package main;

    my $r = hit(ChainApp->to_app, path => '/x');
    is($r->[2][0], 'two wins', 'the first reference return is the response');
    is_deeply(\@ChainApp::ran, [qw(one two)],
        'hooks run in registration order and stop at the short-circuit');
}

# ---- 14. an unknown hook name croaks naming all three ----------------------
{
    package BadHookApp;
    use Punk;
    package main;
    my $err = '';
    eval { BadHookApp::punk_app()->hook(nope => sub { }) } or $err = $@;
    like($err, qr/unknown hook 'nope'/, 'an unknown hook croaks');
    like($err, qr/before_request/,  'naming before_request');
    like($err, qr/before_dispatch/, 'and before_dispatch');
    like($err, qr/after_dispatch/,  'and after_dispatch');
}

# ---- 15. a string target resolves like every other hook -------------------
{
    package StringApp::Controller::Web::Trace;
    our $ran = 0;
    sub start { $ran++; return }
    package StringApp;
    use Punk;
    hook before_request => 'Web::Trace#start';
    get '/x' => sub { $_[0]->text('ok') };
    package main;

    $StringApp::Controller::Web::Trace::ran = 0;
    is(hit(StringApp->to_app, path => '/x')->[0], 200, 'served');
    ok($StringApp::Controller::Web::Trace::ran,
        "'Controller#method' resolves for before_request too");
}

# ---- 16. no hook registered: nothing changes ------------------------------
# The zero-cost path. compile omits the state key entirely when the chain is
# empty, so this app never builds a context before routing.
{
    package PlainApp;
    use Punk;
    get '/x' => sub { $_[0]->text('plain') };
    mount '/psgi' => sub {
        [200, ['Content-Type' => 'text/plain', 'Content-Length' => 2], ['ok']] };
    package main;

    my $app = PlainApp->to_app;
    my $ok = hit($app, path => '/x');
    is($ok->[0], 200, 'a route still answers');
    is($ok->[2][0], 'plain', 'with its body');
    is(hit($app, path => '/nope')->[0], 404, 'a 404 is still a 404');
    is_deeply(file_json_decode(hit($app, path => '/nope')->[2][0]),
        { errors => [ { message => 'Not Found' } ] },
        'in the same shape as ever');
    is(hit($app, path => '/psgi/x')->[2][0], 'ok', 'and a mount still answers');
}

done_testing();
