use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use File::Spec ();
use FindBin ();
use Cwd ();
use JSON::MaybeXS qw(decode_json);
use PAGI::Test::Client;

# The examples themselves use modern Perl (signatures etc.), so this harness can
# only load them on a Perl new enough to parse them. The core framework (lib/ and
# the other test files) runs back to 5.18; the examples do not.
skip_all 'examples require Perl 5.40+ to load' if "$]" < 5.040;

# Every ported example under examples/ must load as a runnable PAGI app and
# behave. Examples are loaded exactly the way pagi-server loads them (set $0 and
# refresh FindBin so each example's FindBin::Bin resolves to its own directory),
# then driven with PAGI::Test::Client. Timer/loop-dependent behavior (background
# workers, keepalive ticks) needs a real event loop, so those examples are
# checked on their deterministic surfaces only.

my $examples = File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'examples');

sub load_example { my ($name) = @_;
    my $file = Cwd::abs_path(File::Spec->catfile($examples, $name, 'app.pl'));
    local $0 = $file;
    FindBin::again();
    my $app = do $file;
    die "loading $name: $@" if $@;
    die "$name did not return a coderef app" unless ref($app) eq 'CODE';
    return $app;
}

subtest 'hello-http' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('hello-http'));
    is $c->get('/')->content, 'Hello, PAGI::Nano!', 'plain text';
};

subtest 'request-body' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('request-body'));
    is $c->post('/echo', body => 'ping')->content, 'ping', 'body echoed';
};

subtest 'utf8-echo' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('utf8-echo'));
    my $j = $c->get("/echo/h\x{e9}llo", query => { text => "na\x{ef}ve" })->json;
    is $j->{from_path}, "h\x{e9}llo", 'path decoded';
    is $j->{length}, 5, 'character length, not byte length';
};

subtest 'websocket-echo' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('websocket-echo'));
    $c->websocket('/', sub { my ($ws) = @_;
        $ws->send_text('hi');
        is $ws->receive_text, 'echo: hi', 'echoed';
    });
};

subtest 'static-file' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('static-file'));
    like $c->get('/')->content, qr/Served by PAGI::Nano/, 'index served at root';
    is $c->get('/index.html')->status, 200, 'named file served';
};

subtest 'lifespan-state' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('lifespan-state'), lifespan => 1);
    $c->start;
    is $c->get('/')->json->{requests}, 1, 'startup state shared';
    is $c->get('/')->json->{requests}, 2, 'state persists';
    $c->stop;
};

subtest 'streaming-response' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('streaming-response'));
    is $c->get('/stream')->content, "chunk 1\nchunk 2\nchunk 3\nchunk 4\nchunk 5\n", 'streamed';
};

subtest 'sse-broadcaster' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('sse-broadcaster'));
    $c->sse('/events', sub { my ($sse) = @_;
        my $e = $sse->receive_event;
        is $e->{event}, 'tick', 'event type';
        is $e->{id}, '1', 'event id';
        is $e->{data}, 'ping 1', 'event data';
    });
};

subtest 'connection-introspection' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('connection-introspection'));
    my $j = $c->get('/conninfo')->json;
    is $j->{scheme}, 'http', 'scheme';
    is $j->{tls}, undef, 'no TLS in plain request';
};

subtest 'bidirectional-websocket' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('bidirectional-websocket'));
    $c->websocket('/', sub { my ($ws) = @_;
        $ws->send_text('hi');
        my @got;
        for (1 .. 3) { my $m = eval { $ws->receive_text }; last unless defined $m; push @got, $m }
        ok((grep { $_ eq 'echo: hi' } @got), 'incoming branch echoes')
            or diag "frames: @got";
    });
};

subtest 'mini-framework' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('mini-framework'));
    is $c->get('/')->content, 'PAGI::Nano is the mini-framework, finished.', 'root';
    is $c->get('/hello/Ada')->content, 'Hello, Ada!', 'path param';
};

subtest 'psgi-bridge' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('psgi-bridge'));
    like $c->get('/')->content, qr/Native Nano route/, 'native route';
    is $c->get('/legacy/foo')->content, 'PSGI app saw: GET /foo', 'mounted PSGI app';
};

subtest 'background-tasks' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('background-tasks'));
    my $r = $c->post('/signup', json => { email => 'a@b.com' });
    is $r->status, 202, 'accepted immediately';
    is $r->json->{status}, 'accepted', 'response returned without waiting for bg work';
};

subtest 'flow-control' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('flow-control'));
    $c->sse('/feed', sub { my ($sse) = @_;
        is $sse->receive_event->{data}, 'reading 1', 'first reading (client keeping up)';
    });
};

subtest 'sse-custom-events' => sub {
    # The periodic ticker and the broadcast fan-out need a real event loop, so
    # in-process we verify the user-driven source (POST /say) and that the SSE
    # stream connects. The broadcast itself is shown by probe.pl / the real-server
    # run in the example header.
    my $c = PAGI::Test::Client->new(app => load_example('sse-custom-events'), lifespan => 1);
    $c->start;
    my $res = $c->post('/say', body => 'hi there');
    is $res->status, 202, 'POST /say accepted (the user-driven source)';
    is $res->json->{broadcast}, 'hi there', 'message published';
    my $connected = 0;
    $c->sse('/events', sub { my ($sse) = @_; $connected = 1 });
    ok $connected, 'SSE stream connects';
    $c->stop;
};

subtest 'full-demo' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('full-demo'), lifespan => 1);
    $c->start;
    is $c->get('/')->json->{requests}, 1, 'lifespan state';
    is $c->post('/echo', json => { message => 'hi' })->json->{you_said}, 'hi', 'params echo';
    is $c->get('/stream')->content, "line 1\nline 2\nline 3\n", 'streaming';
    $c->websocket('/ws/echo', sub { my ($ws) = @_;
        $ws->send_text('x'); is $ws->receive_text, 'echo: x', 'ws echo';
    });
    $c->stop;
};

subtest 'contact-form' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('contact-form'));
    my $ok = $c->post('/submit', form => { email => 'a@b.com', message => 'hello' });
    is $ok->status, 201, 'valid form accepted';
    is $ok->json->{received}, { email => 'a@b.com', message => 'hello' }, 'whitelisted fields';
    my $bad = $c->post('/submit', form => { email => 'a@b.com' });
    is $bad->status, 400, 'missing field rejected';
    is $bad->json->{fields}, ['message'], 'reports the missing field';

    # A multipart submission exercises the optional file-upload branch
    # ($c->req->upload('attachment')), which the urlencoded form cannot reach.
    my $boundary = 'NanoContactBoundary';
    my $body = join "\r\n",
        "--$boundary",
        'Content-Disposition: form-data; name="email"', '', 'a@b.com',
        "--$boundary",
        'Content-Disposition: form-data; name="message"', '', 'with a file',
        "--$boundary",
        'Content-Disposition: form-data; name="attachment"; filename="note.txt"',
        'Content-Type: text/plain', '', 'file body contents',
        "--$boundary--", '';
    my $up = $c->post('/submit',
        body    => $body,
        headers => { 'Content-Type' => "multipart/form-data; boundary=$boundary" },
    );
    is $up->status, 201, 'multipart submission accepted';
    is $up->json->{attachment}{filename}, 'note.txt',
        'the uploaded file is surfaced through $c->req->upload';
};

subtest 'periodic-events' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('periodic-events'), lifespan => 1);
    $c->start;
    ok exists $c->get('/')->json->{ticks}, 'tick count available immediately';
    $c->stop;
};

subtest 'job-runner' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('job-runner'), lifespan => 1);
    $c->start;
    my $created = $c->post('/api/jobs', json => { label => 'resize' });
    is $created->status, 201, 'job created';
    is $created->json->{status}, 'queued', 'starts queued';
    is scalar(@{ $c->get('/api/jobs')->json }), 1, 'listed';
    is $c->get('/api/jobs/1')->json->{label}, 'resize', 'fetched by id';
    is $c->get('/api/jobs/999')->status, 404, 'unknown job 404';
    $c->stop;
};

subtest 'chat-showcase' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('chat-showcase'), lifespan => 1);
    $c->start;
    is $c->get('/api/rooms')->json, ['general'], 'seeded room';
    $c->websocket('/ws/chat', sub { my ($ws) = @_;
        $ws->send_json({ join => 'general', user => 'ada' });
        like $ws->receive_json->{system}, qr/joined general/, 'join ack';
        $ws->send_json({ text => 'hello' });
        my $b = $ws->receive_json;
        is $b->{user}, 'ada', 'broadcast user';
        is $b->{text}, 'hello', 'broadcast text';
    });
    is scalar(@{ $c->get('/api/room/general/history')->json }), 1, 'message recorded';
    $c->stop;
};

subtest 'duplex-http-stream' => sub {
    # The in-process client stays connected for the whole request (it cannot
    # disconnect mid-response), so we bound the run with ?ticks=1 and exercise
    # BOTH branches: the body echo and the tick loop. The unbounded
    # connection-driven behavior (ticks until the client goes away, later body
    # chunks echoed mid-response) is proven by
    # examples/duplex-http-stream/probe.pl against pagi-server.
    my $c = PAGI::Test::Client->new(app => load_example('duplex-http-stream'));
    my $res = $c->post('/duplex?ticks=1', body => 'ping');
    is $res->status, 200, 'streamed 200';
    like $res->content, qr/echo: ping/, 'request body echoed';
    like $res->content, qr/tick 1/,     'tick loop ran (bounded by ?ticks)';
};

subtest 'custom-send-events' => sub {
    # One handler emits domain app.events; two route-scoped renderer middlewares
    # produce SSE or NDJSON at the same /feed URL, each adding a sequence number
    # the app never sets. A burst (no timer), so both formats are testable here.
    my $c = PAGI::Test::Client->new(app => load_example('custom-send-events'));

    # SSE: Accept: text/event-stream promotes to the sse route + SSE renderer.
    $c->sse('/feed', sub {
        my ($sse) = @_;
        my $e1 = $sse->receive_event;
        is $e1->{event}, 'status', 'SSE: middleware named the event from the domain event';
        my $d1 = decode_json($e1->{data});
        is $d1->{value}, 'online', 'SSE: app payload preserved';
        is $d1->{seq}, 1, 'SSE: middleware added a sequence number';
    });

    # NDJSON: a plain GET to the SAME URL hits the raw route + NDJSON renderer.
    my $res = $c->get('/feed');
    is $res->status, 200, 'NDJSON: 200';
    like $res->content_type, qr{application/x-ndjson}, 'NDJSON content type';
    my @lines = grep { length } split /\n/, $res->content;
    is scalar(@lines), 4, 'NDJSON: one line per domain event';
    my $first = decode_json($lines[0]);
    is $first->{event}, 'status', 'NDJSON: same domain event, different wire format';
    is $first->{seq}, 1, 'NDJSON: enriched with seq too';
};

subtest 'mounted-stash-state' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('mounted-stash-state'), lifespan => 1);
    $c->start;

    my $ada = $c->get('/api/hello', headers => { 'X-User' => 'Ada' })->json;
    is $ada->{user}, 'Ada', 'stash set by parent middleware reaches the mounted app';
    is $ada->{greeting}, 'Hello, Ada!', 'lifecycle greeter from startup is usable in the mount';
    is $ada->{greetings_so_far}, 1, 'lifecycle object state is live';

    my $bob = $c->get('/api/hello', headers => { 'X-User' => 'Bob' })->json;
    is $bob->{user}, 'Bob', 'stash is per-request';
    is $bob->{greetings_so_far}, 2, 'same lifecycle instance is shared across requests';

    is $c->get('/greetings')->json->{greetings_so_far}, 2,
        'parent and mounted app share the very same lifecycle object in state';
    $c->stop;
};

subtest 'named-routes' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('named-routes'));

    my $home = $c->get('/')->json;
    is $home->{first_user}, '/api/users/1', 'parent links to a name in the mount (prefixed)';

    my $user = $c->get('/api/users/7')->json;
    is $user->{self}, '/api/users/7', 'mount links its own name with the mount prefix';
    is $user->{edit}, '/api/users/7?edit=1', 'query string included';
    is $user->{back_home}, '/', 'mount links to a name in the parent';
};

subtest 'rest-resource' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('rest-resource'));
    is $c->get('/widgets')->json, [], 'empty collection';
    my $made = $c->post('/widgets', json => { name => 'sprocket' });
    is $made->status, 201, 'POST creates -> 201';
    my $id = $made->json->{id};
    is $c->get("/widgets/$id")->json->{name}, 'sprocket', 'GET one';
    is $c->put("/widgets/$id", json => { name => 'cog', qty => 3 })->json,
        { id => $id, name => 'cog', qty => 3 }, 'PUT replaces';
    is $c->patch("/widgets/$id", json => { qty => 9 })->json->{qty}, 9, 'PATCH merges qty';
    is $c->patch("/widgets/$id", json => { qty => 9 })->json->{name}, 'cog', 'PATCH leaves name';
    is $c->delete("/widgets/$id")->status, 204, 'DELETE -> 204 No Content';
    is $c->get("/widgets/$id")->status, 404, 'gone -> 404';
    is $c->get('/no/such/path')->status, 404, 'not_found -> 404';
};

subtest 'strong-params-deep' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('strong-params-deep'));
    my $order = $c->post('/orders', json => {
        customer => 'Ada',
        address  => { street => '1 Calc Ln', city => 'London' },
        coupons  => ['EARLY', 'VIP'],
        items    => [ { sku => 'A1', qty => '2' }, { sku => 'B2', qty => '1' } ],
        junk     => 'dropped',
    });
    is $order->status, 201, 'valid nested order accepted';
    is $order->json->{accepted}, {
        customer => 'Ada',
        address  => { street => '1 Calc Ln', city => 'London' },
        coupons  => ['EARLY', 'VIP'],
        items    => [ { sku => 'A1', qty => '2' }, { sku => 'B2', qty => '1' } ],
    }, 'nested hash, bare array, and array-of-hashes all shaped; junk dropped';

    is $c->post('/orders', json => { address => { city => 'x' } })->status, 400,
        'missing required customer -> 400';

    my $prof = $c->post('/profile', form => { 'user.name' => 'Ada', 'user.email' => 'ada@calc.dev', spam => 'x' });
    is $prof->json, { user => { name => 'Ada', email => 'ada@calc.dev' } },
        'namespace + dotted flat keys reconstruct a nested hash; spam dropped';
};

subtest 'sessions' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('sessions'));
    my $first = $c->get('/');
    is $first->json->{you_are}, 'guest', 'no session -> guest';
    # carry the session cookie forward
    my $cookie = $first->header('set-cookie');
    ok $cookie, 'a session cookie was set';
    (my $pair = $cookie) =~ s/;.*//;     # name=value
    my $login = $c->post('/login', form => { user => 'ada' }, headers => { Cookie => $pair });
    is $login->status, 303, 'login redirects (Post/Redirect/Get)';
    my $after = $c->get('/', headers => { Cookie => $pair });
    is $after->json->{you_are}, 'ada', 'session persists the logged-in user across requests';
};

subtest 'error-handling' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('error-handling'));
    is $c->get('/ok')->status, 200, 'normal route 200';
    my $teapot = $c->get('/teapot');
    is $teapot->status, 418, 'die-a-respond-able sends the chosen status';
    is $teapot->json->{error}, "I'm a teapot", 'and its body';
    is $c->get('/boom')->status, 500, 'an uncaught die is a 500';
    is $c->get('/nowhere')->status, 404, 'not_found handles the miss';
};

subtest 'custom-middleware' => sub {
    my $c = PAGI::Test::Client->new(app => load_example('custom-middleware'));
    my $public = $c->get('/public');
    is $public->status, 200, 'public route open';
    ok defined $public->header('x-response-time-ms'),
        'app-wide RequestTimer injected the timing header';
    is $c->get('/private')->status, 401, 'ApiKey rejects without the key';
    is $c->get('/private', headers => { 'X-Api-Key' => 's3cr3t' })->json->{secret},
        'the answer is 42', 'ApiKey admits the right key';
};

subtest 'game-of-life (the showcase)' => sub {
    my $app = load_example('game-of-life');

    # The Conway engine is pure and deterministic: a blinker (three in a row)
    # oscillates with period two, returning to its start after two generations.
    my $w = GoL::World->new(10, 10);
    $w->toggle(4, 5); $w->toggle(5, 5); $w->toggle(6, 5);
    my $gen0 = $w->frame->{rows};
    $w->step;
    my $gen1 = $w->frame->{rows};
    $w->step;
    is $w->frame->{rows}, $gen0, 'a blinker returns to its start after 2 generations';
    isnt $gen1, $gen0, 'and differs at the half-period';

    # The HTTP/SSE surface (the world lives in lifespan state, so start it).
    my $c = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $c->start;

    like $c->get('/')->content_type, qr{text/html}, 'the / client page is HTML';

    my $grid = $c->get('/grid')->json;
    is $grid->{w}, 48, 'grid width';
    is scalar(@{ $grid->{rows} }), 28, '28 rows in the snapshot';
    is length($grid->{rows}[0]), 48, 'each row is 48 cells wide';

    is $c->post('/cell/10/10')->status, 202, 'POST /cell/:x/:y toggles a cell -> 202';

    $c->sse('/live', sub {
        my ($sse) = @_;
        my $ev = $sse->receive_event;
        is $ev->{event}, 'frame', 'the live feed emits frame events';
        my $f = decode_json($ev->{data});
        ok exists $f->{generation}, 'a frame carries its generation';
        is scalar(@{ $f->{rows} }), 28, 'a frame carries the whole grid';
    });

    $c->stop;
};

subtest 'run-shape examples still load' => sub {
    my $qs = load_example('quickstart');
    is ref($qs), 'CODE', 'quickstart app.pl loads';
    # tasks-modulino is covered by t/07-run-shapes.t
};

done_testing;
