#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use Types::Standard qw(Str);
use JSON::PP qw(decode_json);
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);

# Helper: run one request through a PAGI app and return (status, decoded_body).
sub run_request ($pagi_app, $scope, $receive = undef) {
    $receive //= async sub { return { type => 'http.request', more_body => 0 } };

    my $sent_start;
    my $sent_body;
    my $send = async sub ($event) {
        if ($event->{type} eq 'http.response.start') {
            $sent_start = $event;
        }
        elsif ($event->{type} eq 'http.response.body') {
            $sent_body = $event;
        }
    };

    $pagi_app->($scope, $receive, $send)->get;

    my $decoded;
    if (defined $sent_body->{body} && length $sent_body->{body}) {
        $decoded = eval { decode_json($sent_body->{body}) };
    }
    return ($sent_start->{status}, $decoded, $sent_body->{body});
}

subtest 'Literal path segments are regex-escaped' => sub {
    my $app = PAGI::FastAPI->new(title => 'Escape Test');
    $app->get('/items.json/{id}', handler => async sub ($c) {
        return { id => $c->path_param('id') };
    });
    my $pagi_app = $app->to_app;

    # A literal '.' must NOT act as a regex wildcard.
    my ($status1) = run_request($pagi_app, {
        type => 'http', method => 'GET', path => '/itemsXjson/5',
        query_string => '', headers => [],
    });
    is $status1, 404, "'.' in a static path segment does not match arbitrary characters";

    my ($status2, $data2) = run_request($pagi_app, {
        type => 'http', method => 'GET', path => '/items.json/5',
        query_string => '', headers => [],
    });
    is $status2, 200, 'the literal path still matches itself';
    is $data2->{id}, '5', 'path param captured correctly';
};

subtest 'Query and path values are percent-decoded' => sub {
    my $app = PAGI::FastAPI->new(title => 'Decode Test');
    $app->get('/search', query => { q => Str }, handler => async sub ($c) {
        return { q => $c->query_param('q') };
    });
    $app->get('/user/{name}', handler => async sub ($c) {
        return { name => $c->path_param('name') };
    });
    my $pagi_app = $app->to_app;

    my ($status, $data) = run_request($pagi_app, {
        type => 'http', method => 'GET', path => '/search',
        query_string => 'q=hello%20world%2Bfoo', headers => [],
    });
    is $status, 200, 'decoded query request succeeds';
    is $data->{q}, 'hello world+foo', 'query value is percent- and plus-decoded';

    my ($status2, $data2) = run_request($pagi_app, {
        type => 'http', method => 'GET', path => '/user/John%20Doe',
        query_string => '', headers => [],
    });
    is $status2, 200, 'decoded path request succeeds';
    is $data2->{name}, 'John Doe', 'path param is percent-decoded';
};

subtest 'Body-read loop does not hang on a non-request event' => sub {
    my $app = PAGI::FastAPI->new(title => 'Disconnect Test');
    $app->post('/items', handler => async sub ($c) { return { ok => 1 } });
    my $pagi_app = $app->to_app;

    my $receive = async sub { return { type => 'http.disconnect' } };

    my ($status) = run_request($pagi_app, {
        type => 'http', method => 'POST', path => '/items',
        query_string => '', headers => [],
    }, $receive);

    ok defined $status, 'request completed instead of hanging on an unexpected receive event';
};

subtest 'Route registration validates required options' => sub {
    my $app = PAGI::FastAPI->new(title => 'Validation Test');

    eval { $app->get('/no-handler') };
    like $@, qr/requires a 'handler'/, 'registering a route without a handler dies';

    eval { $app->get('/bad-deps', dependencies => 'oops', handler => async sub {}) };
    like $@, qr/'dependencies' must be a HashRef or ArrayRef/, 'a malformed dependencies value dies';

    eval {
        $app->get('/bad-dep-entry',
            dependencies => [ 'not a coderef' ],
            handler      => async sub {},
        );
    };
    like $@, qr/unrecognized dependency entry/, 'an unrecognized dependency array entry dies';

    eval {
        $app->get('/good',
            dependencies => [ Depends(async sub { 1 }, key => 'x') ],
            handler      => async sub { return { ok => 1 } },
        );
    };
    is $@, '', 'a valid route with a Depends() entry registers without error';
};

done_testing;
