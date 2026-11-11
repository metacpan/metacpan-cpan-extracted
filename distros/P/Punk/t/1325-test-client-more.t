#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::Builder::Tester;
use Test::More;
use Punk::Test;
use Punk::Test::WS ();

# More of Punk::Test: patch_ok, csrf => 1 before any cookie is held, a
# streaming response that writes a list of chunks, an SSE event compared as
# a structure, an in-process websocket whose handler closes at once so a
# message assertion sees the close, one whose application returns nothing,
# and the headers a websocket upgrade may carry.

{
    package MoreApp;
    use Punk;
    patch '/p'   => sub { $_[0]->text('patched') };
    get '/t'     => sub { $_[0]->text('t') };
    get '/chunks' => sub {
        my ($c) = @_;
        return sub { my $r = shift; my $w = $r->([ 200, [ 'Content-Type' => 'text/plain' ] ]); $w->write($_) for 'a', 'b', 'c'; $w->close };
    };
    get '/list' => sub { return sub { $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ], [ 'x', 'y' ] ]) } };
    sse '/evj'   => sub { my ($c, $s) = @_; $s->send({ z => [ 1, 2 ], w => { k => 'v' } }); $s->close };
    websocket '/bye' => sub { my ($c, $ws) = @_; $ws->on(open => sub { $_[0]->close(1000, 'bye') }) }, { blocking => 1 };
    websocket '/echo' => sub { my ($c, $ws) = @_; $ws->on(message => sub { $_[0]->send("echo:$_[1]") }) }, { blocking => 1 };
    websocket '/quiet' => sub { my ($c, $ws) = @_; $ws->on(message => sub { }) }, { blocking => 1 };
    del '/d' => sub { $_[0]->text('deleted') };
    any '/o' => sub { $_[0]->text('any') };
    post '/up' => sub { my ($c) = @_; $c->text('note=' . ($c->param('note') // 'undef')) };
    get '/hdr' => sub { my ($c) = @_; $c->res->header('X-Y' => 'z'); $c->text($c->res->header('X-Y') // 'none') };
    package main;
}
my $t = Punk::Test->new('MoreApp');

$t->patch_ok('/p')->status_is(200)->content_is('patched', 'patch_ok is a request like the others');
$t->get_ok('/chunks')->status_is(200)->content_is('abc', 'a streaming writer\'s chunks are gathered');
$t->get_ok('/list')->status_is(200)->content_is('xy', 'a responder given a list body is gathered too');
$t->sse_ok('/evj')->sse_json_is(0, '/z', [ 1, 2 ], 'an event compared as a list')
  ->sse_json_is(0, '/w', { k => 'v' }, 'and as a mapping')
  ->sse_json_is(0, '/w/k', 'v', 'and a scalar inside it');

{
    my $fresh = Punk::Test->new('MoreApp');
    test_out('ok 1 - GET /t');
    test_diag("csrf => 1, but the jar holds no 'csrf' cookie yet - GET a page first");
    $fresh->get_ok('/t', csrf => 1);
    test_test('csrf => 1 before any cookie is held says what to do');
}

SKIP: {
    skip 'fork is not Windows', 4 if $^O eq 'MSWin32';
    my $w = Punk::Test->new('MoreApp');
    $w->websocket_ok('/echo')->send_ok('hi')->message_is('echo:hi', 'an in-process websocket echoes');
    $w->finish_ok;
    my $b = Punk::Test->new('MoreApp');
    $b->websocket_ok('/bye', headers => { 'X-Extra' => 'yes' });
    test_out('not ok 1 - message is');
    test_fail(+2);
    test_diag('the server closed instead');
    $b->message_is('never', 'message is');
    test_test('a message assertion against a server that closed says so');
}

$t->get_ok('/hdr')->status_is(200)->content_is('z', 'a response header reads back by name');
$t->post_ok('/up', form => { note => '' }, upload => { file => [ \'bytes', 'a.txt', 'text/plain' ] })->status_is(200, 'a multipart request with an empty field is built');

$t->delete_ok('/d')->status_is(200)->content_is('deleted', 'delete_ok is a request like the others');
$t->options_ok('/o')->status_is(200)->content_is('any', 'and so is options_ok');

SKIP: {
    skip 'fork is not Windows', 11 if $^O eq 'MSWin32';
    my $w = Punk::Test->new('MoreApp');
    $w->websocket_ok('/echo')->send_ok('hi')->message_like(qr/^echo:hi$/, 'message_like matches the echo');
    ok(defined fileno($w->{ws}->sock), 'the connection exposes its socket');
    $w->finish_ok;
    my $b = Punk::Test->new('MoreApp');
    $b->websocket_ok('/bye');
    test_out('not ok 1 - message matches');
    test_fail(+2);
    test_diag('the server closed instead');
    $b->message_like(qr/never/);
    test_test('message_like against a server that closed says so');
    my $q = Punk::Test->new('MoreApp', timeout => 1);
    $q->websocket_ok('/quiet');
    test_out('not ok 1 - message matches');
    test_fail(+2);
    test_diag('no frame arrived (timeout or EOF)');
    $q->message_like(qr/never/);
    test_test('message_like with nothing arriving says so');
    my $q2 = Punk::Test->new('MoreApp', timeout => 1);
    $q2->websocket_ok('/quiet');
    test_out('not ok 1 - message is');
    test_fail(+2);
    test_diag('no frame arrived (timeout or EOF)');
    $q2->message_is('never', 'message is');
    test_test('message_is with nothing arriving says so');
}

done_testing;
