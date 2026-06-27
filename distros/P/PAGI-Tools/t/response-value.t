use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Response;

sub recorder {
    my @events;
    my $send = sub { my ($e) = @_; push @events, $e; Future->done };
    return ($send, \@events);
}

subtest 'detached new + respond($send) emits start+body' => sub {
    my $res = PAGI::Response->new;                 # no connection, no scope
    $res->status(201)->header('X-A' => '1')->_set_body('hi', 'text/plain');

    my ($send, $events) = recorder();
    $res->respond($send)->get;

    is $events->[0]{type}, 'http.response.start', 'start first';
    is $events->[0]{status}, 201, 'status carried';
    my %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    is $h{'x-a'}, '1', 'header carried';
    is $h{'content-length'}, 2, 'content-length computed';
    is $events->[1]{type}, 'http.response.body', 'body second';
    is $events->[1]{body}, 'hi', 'body bytes';
    is $events->[1]{more}, 0, 'final chunk';
};

subtest 'a response value is reusable across connections (re-entrant)' => sub {
    my $res = PAGI::Response->new->_set_body('x', 'text/plain');
    my ($s1, $e1) = recorder();
    my ($s2, $e2) = recorder();
    $res->respond($s1)->get;
    $res->respond($s2)->get;
    is $e1->[1]{body}, 'x', 'first connection';
    is $e2->[1]{body}, 'x', 'second connection — same value, no leaked state';
};

subtest 'to_app wraps respond' => sub {
    my $res = PAGI::Response->new->_set_body('app', 'text/plain');
    my $app = $res->to_app;
    is ref($app), 'CODE', 'coderef';
    my ($send, $events) = recorder();
    $app->({}, sub { Future->done }, $send)->get;
    is $events->[1]{body}, 'app', 'mounted response serves its body';
};

subtest 'respond drives a stream callback' => sub {
    my $res = PAGI::Response->new->content_type('text/plain');
    $res->{_stream} = async sub {        # Task 3's stream($cb) will set this publicly
        my ($writer) = @_;
        await $writer->write('a');
        await $writer->write('b');
    };
    my ($send, $events) = recorder();
    $res->respond($send)->get;
    is $events->[0]{type}, 'http.response.start', 'start first';
    ok !(grep { lc($_->[0]) eq 'content-length' } @{$events->[0]{headers}}),
        'no content-length for a stream';
    my @body = grep { $_->{type} eq 'http.response.body' } @$events;
    is join('', map { $_->{body} // '' } @body), 'ab', 'chunks streamed';
    is $body[-1]{more}, 0, 'final chunk closes the stream';
};

subtest 'body methods set body and return self (class or instance)' => sub {
    my $res = PAGI::Response->new;
    ref_is $res->text('hi'), $res, 'instance text returns $self';

    my ($send, $events) = recorder();
    PAGI::Response->json({ ok => 1 })->respond($send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    like $h{'content-type'}, qr{application/json}, 'json content-type';
    like $events->[1]{body}, qr/"ok"\s*:\s*1/, 'json body';

    ($send, $events) = recorder();
    PAGI::Response->text('hello')->status(202)->respond($send)->get;
    is $events->[0]{status}, 202, 'factory value still chains status';
    is $events->[1]{body}, 'hello', 'text body';

    ($send, $events) = recorder();
    PAGI::Response->new->content_type('text/markdown')->text('hi')->respond($send)->get;
    my %ct = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    is $ct{'content-type'}, 'text/markdown; charset=utf-8',
        'explicit content_type wins, with charset appended for the UTF-8 body';

    ($send, $events) = recorder();
    PAGI::Response->redirect('/login')->respond($send)->get;
    is $events->[0]{status}, 302, 'redirect default status';
    my %rh = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    is $rh{location}, '/login', 'redirect location';

    ($send, $events) = recorder();
    PAGI::Response->new->status(200)->redirect('/x', 308)->respond($send)->get;
    is $events->[0]{status}, 308, 'explicit redirect status wins over prior status';

    ($send, $events) = recorder();
    PAGI::Response->new->empty->respond($send)->get;
    is $events->[0]{status}, 204, 'empty default 204';
};

subtest 'factory %opts: status / headers / content_type' => sub {
    my ($send, $events) = recorder();
    PAGI::Response->json({ error => 'nope' }, status => 404)->respond($send)->get;
    is $events->[0]{status}, 404, 'json opts status applied';

    ($send, $events) = recorder();
    PAGI::Response->text('hi', status => 201, headers => ['X-Foo' => 'bar'])->respond($send)->get;
    is $events->[0]{status}, 201, 'text opts status';
    my %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    is $h{'x-foo'}, 'bar', 'opts headers applied';

    ($send, $events) = recorder();
    PAGI::Response->send_raw('xyz', content_type => 'application/octet-stream')->respond($send)->get;
    %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    is $h{'content-type'}, 'application/octet-stream', 'opts content_type';

    ($send, $events) = recorder();
    PAGI::Response->html('<p>hi</p>', status => 418)->respond($send)->get;
    is $events->[0]{status}, 418, 'html opts status';
    %h = map { lc($_->[0]) => $_->[1] } @{$events->[0]{headers}};
    like $h{'content-type'}, qr{text/html}, 'html keeps its content-type';

    ($send, $events) = recorder();
    PAGI::Response->empty(status => 304)->respond($send)->get;
    is $events->[0]{status}, 304, 'empty opts status overrides the 204 default';

    like dies { PAGI::Response->json({}, staus => 404) },
        qr/[Uu]nknown response option 'staus'/,
        'unknown opt croaks (catches typos)';

    like dies { PAGI::Response->text('x', headers => ['X-Only']) },
        qr/even-length/,
        'odd-length headers arrayref croaks';
};

subtest 'has_body_source reflects a registered body source (intent, not bytes)' => sub {
    is(PAGI::Response->new->has_body_source, 0, 'fresh response: no body source');

    is(PAGI::Response->new->text('hi')->has_body_source,     1, 'text sets a body source');
    is(PAGI::Response->new->html('<p>')->has_body_source,    1, 'html sets a body source');
    is(PAGI::Response->new->json({})->has_body_source,       1, 'json sets a body source');
    is(PAGI::Response->new->send_raw('x')->has_body_source,  1, 'send_raw sets a body source');
    is(PAGI::Response->new->send('x')->has_body_source,      1, 'send sets a body source');

    # Intentional empty bodies set _body to '' and MUST count (exists, not length).
    is(PAGI::Response->new->empty->has_body_source,          1, 'empty is a body source (empty body)');
    is(PAGI::Response->new->redirect('/x')->has_body_source, 1, 'redirect is a body source (empty body)');

    # A stream is a registered source BEFORE it runs (zero bytes produced).
    is(PAGI::Response->new->stream(async sub {})->has_body_source, 1,
        'stream registers a body source before respond runs it');

    is(PAGI::Response->new->send_file($0)->has_body_source, 1,
        'send_file registers a body source (the _file slot)');

    # Status-only is NOT a body source — proves the framework needs `|| has_status`.
    my $status_only = PAGI::Response->new->status(204);
    is $status_only->has_body_source, 0, 'status without a body method: no body source';
    is $status_only->has_status,      1, 'but has_status is true (redirect/204 need this)';

    # respond() does not mutate, so the predicate is stable after sending.
    my $res = PAGI::Response->new->text('hi');
    my $send = sub { Future->done };
    $res->respond($send)->get;
    is $res->has_body_source, 1, 'has_body_source unchanged after respond (value is non-mutating)';
};

done_testing;
