#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::Builder::Tester;
use Test::More;
use Punk::Test;

# What Punk::Test says when an assertion fails, checked by capturing the TAP
# it emits: no response to assert on, an application that dies or returns
# nonsense, JSON that is not there, an SSE stream that is not one, events the
# stream never held, event data that is not JSON, and the websocket helpers
# called before an upgrade.

{
    package FailApp;
    use Punk;
    get '/t'    => sub { $_[0]->text('hello') };
    get '/j'    => sub { $_[0]->json({ a => 1 }) };
    get '/long' => sub { $_[0]->text('x' x 600) };
    get '/setc' => sub { $_[0]->header('Set-Cookie' => 'k=v; Path=/'); $_[0]->text('set') };
    sse '/ev'   => sub { my ($c, $s) = @_; $s->event(tick => 'x'); $s->close };
    sse '/evj'  => sub { my ($c, $s) = @_; $s->retry(500); $s->send({ z => 1 }); $s->close };
    package main;
}
my $t = Punk::Test->new('FailApp');

# ---- no response yet -----------------------------------------------------------
test_out('not ok 1 - status is 200');
test_fail(+2);
test_diag('no response - did the last *_ok request fail?');
$t->status_is(200);
test_test('status_is before any request fails and says why');

# ---- the application dies, or answers nonsense ------------------------------------
{
    my $dies = Punk::Test->new(sub { die "boom\n" });
    test_out('not ok 1 - GET /x');
    test_fail(+2);
    test_diag('the application died: boom');
    $dies->get_ok('/x');
    test_test('an application that dies fails the request');
    my $odd = Punk::Test->new(sub { 'nope' });
    test_out('not ok 1 - GET /x');
    test_fail(+2);
    test_diag('the application did not return a PSGI response');
    $odd->get_ok('/x');
    test_test('an application that returns no response fails the request');
}

# ---- JSON that is not there ----------------------------------------------------------
test_out('ok 1 - GET /t', 'not ok 2 - json at \'/a\'');
test_fail(+2);
test_diag('the body did not decode as JSON: hello');
$t->get_ok('/t')->json_is('/a', 1);
test_test('json_is on a body that is not JSON');
test_out('ok 1 - GET /j', 'not ok 2 - json at \'/nope\'');
test_fail(+2);
test_diag('nothing at JSON pointer \'/nope\' in {"a":1}');
$t->get_ok('/j')->json_is('/nope', 1);
test_test('json_is on a pointer that leads nowhere');
test_out('ok 1 - GET /j', 'not ok 2 - json at \'/a/b\'');
test_fail(+2);
test_diag('nothing at JSON pointer \'/a/b\' in {"a":1}');
$t->get_ok('/j')->json_is('/a/b', 1);
test_test('json_is on a pointer through a scalar');
test_out('ok 1 - PUT /t');
$t->put_ok('/t');
test_test('put_ok is a request like the others');

# ---- a long body in a failure's diagnostic ---------------------------------------------
test_out('ok 1 - GET /long', 'not ok 2 - status is 201');
test_fail(+2);
test_diag('         got: 200', '    expected: 201', 'body: ' . ('x' x 500) . '...');
$t->get_ok('/long')->status_is(201);
test_test('a failure shows the first 500 bytes of the body');

# ---- SSE -----------------------------------------------------------------------------
test_out('not ok 1 - SSE /t');
test_fail(+2);
test_diag('expected a 200 text/event-stream, got 200 text/plain; charset=utf-8: hello');
$t->sse_ok('/t');
test_test('sse_ok on a route that is not a stream');
test_out('not ok 1 - event 0 is tick');
test_fail(+2);
test_diag('no SSE stream - did sse_ok pass?');
$t->sse_event_is(0, 'tick', 'x');
test_test('an event assertion with no stream');
test_out('ok 1 - SSE /ev', 'not ok 2 - event 5 is tick');
test_fail(+2);
test_diag('no event 5 - the stream held 1 event(s)');
$t->sse_ok('/ev')->sse_event_is(5, 'tick', 'x');
test_test('an event the stream never held');
test_out('ok 1 - SSE /ev', 'not ok 2 - event 0 is other');
test_fail(+2);
test_diag("event 0 is named 'tick', not 'other'");
$t->sse_ok('/ev')->sse_event_is(0, 'other', 'x');
test_test('an event with another name');
test_out('ok 1 - SSE /ev', 'not ok 2 - event 0 json at \'/z\'');
test_fail(+2);
test_diag('event 0 data is not JSON: x');
$t->sse_ok('/ev')->sse_json_is(0, '/z', 1);
test_test('event data that is not JSON');
test_out('ok 1 - SSE /evj', 'not ok 2 - event 0 json at \'/q\'');
test_fail(+2);
test_diag("nothing at JSON pointer '/q' in event 0");
$t->sse_ok('/evj')->sse_json_is(0, '/q', 1);
test_test('a pointer into event data that leads nowhere');
test_out('ok 1 - SSE /evj', 'ok 2 - event 0 json at \'/z\'');
$t->sse_ok('/evj')->sse_json_is(0, '/z', 1);
test_test('and one that does not');
is($t->sse_events->[0]{retry}, 500, 'a retry field is parsed');

# ---- websocket helpers before an upgrade ------------------------------------------------
for my $case ([ send_ok => 'send', 'x' ], [ message_is => 'message is', 'x', 'message is' ],
              [ message_like => 'message matches', qr/x/ ], [ finish_ok => 'clean close' ]) {
    my ($method, $name, @args) = @$case;
    test_out("not ok 1 - $name");
    test_fail(+2);
    test_diag('no websocket - did websocket_ok pass?');
    $t->$method(@args);
    test_test("$method without a websocket");
}

# ---- an SSE route on an application that dies or answers nothing ----------------------
{
    my $dies = Punk::Test->new(sub { die "boom\n" });
    test_out('not ok 1 - SSE /x');
    test_fail(+2);
    test_diag('the application died: boom');
    $dies->sse_ok('/x');
    test_test('sse_ok on an application that dies');
    my $odd = Punk::Test->new(sub { 'nope' });
    test_out('not ok 1 - SSE /x');
    test_fail(+2);
    test_diag('no response from the sse route');
    $odd->sse_ok('/x');
    test_test('sse_ok on an application that answers nothing');
}

# ---- an upgrade the application answers nothing to, and one a live worker declines ---
SKIP: {
    skip 'fork is not Windows', 1 if $^O eq 'MSWin32';
    my $none = Punk::Test->new(sub { return });
    test_out('not ok 1 - websocket /x');
    test_fail(+2);
    test_diag('the upgrade was answered with a 500:', "HTTP/1.1 500 X\r", "\r");
    $none->websocket_ok('/x');
    test_test('websocket_ok on an application that returns nothing');
}
SKIP: {
    skip 'the live transport needs Hyperman 0.11+', 2 unless Punk::Test::ws_live_available();
    my $live = Punk::Test->new('FailApp');
    $live->get_ok('/setc');
    test_out('not ok 1 - websocket /t');
    test_fail(+2);
    test_diag('the upgrade was answered with: HTTP/1.1 200 OK');
    $live->websocket_ok('/t', live => 1, headers => { 'X-Extra' => 'yes' });
    test_test('a live upgrade of a plain route says what came back');
}

done_testing;
