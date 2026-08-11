#!/usr/bin/env perl

use v5.36;
use Test::More;
use Future::AsyncAwait;
use JSON::PP qw(encode_json decode_json);
use PAGI::FastAPI;

# Helper async function returns a Future object
async sub run_pagi_request ($app, $path, $method = 'GET', $headers = [], $body = '') {
    my $response_status;
    my %response_headers;
    my $response_body = '';

    my $scope = {
        type    => 'http',
        method  => $method,
        path    => $path,
        headers => $headers,
    };

    my $sent = 0;
    my $receive = async sub {
        return { type => 'http.request', body => $body, more_body => 0 } if $sent++ == 0;
        return { type => 'http.disconnect' };
    };

    my $send = async sub ($event) {
        if ($event->{type} eq 'http.response.start') {
            $response_status  = $event->{status};
            %response_headers = map { $_->[0] => $_->[1] } @{$event->{headers} // []};
        } elsif ($event->{type} eq 'http.response.body') {
            $response_body .= $event->{body} // '';
        }
    };

    await $app->to_app->($scope, $receive, $send);

    my $json = eval { decode_json($response_body) };
    return { status => $response_status, headers => \%response_headers, body => $response_body, json => $json };
}

subtest 'Custom Timing/Response Wrapper Middleware' => sub {
    my $app = PAGI::FastAPI->new();

    $app->add_middleware(async sub ($c, $next) {
        $c->set_header('X-Process-Time' => '0.005s');
        my $res = await $next->($c);
        $res->{processed} = 1;
        return $res;
    });

    $app->get('/ping', handler => async sub ($c) {
        return { message => 'pong' };
    });

    my $res = run_pagi_request($app, '/ping')->get;
    is $res->{status}, 200, 'Status 200';
    is $res->{headers}{'X-Process-Time'}, '0.005s', 'Custom response header attached';
    is $res->{json}{processed}, 1, 'Middleware modified response hash';
};

subtest 'CORS Middleware & OPTIONS Preflight' => sub {
    my $app = PAGI::FastAPI->new();
    $app->add_cors(origins => ['https://frontend.com']);

    $app->get('/api/data', handler => async sub ($c) { return { data => 123 }; });

    # 1. Preflight OPTIONS Request
    my $preflight = run_pagi_request($app, '/api/data', 'OPTIONS', [['Origin', 'https://frontend.com']])->get;
    is $preflight->{status}, 204, 'Preflight status is 204 No Content';
    is $preflight->{headers}{'Access-Control-Allow-Origin'}, 'https://frontend.com', 'CORS origin header present';

    # 2. Regular GET Request with Origin
    my $get_res = run_pagi_request($app, '/api/data', 'GET', [['Origin', 'https://frontend.com']])->get;
    is $get_res->{status}, 200, 'GET status is 200';
    is $get_res->{headers}{'Access-Control-Allow-Origin'}, 'https://frontend.com', 'CORS origin header attached';
};

subtest 'Authentication Hook Middleware' => sub {
    my $app = PAGI::FastAPI->new();

    $app->add_middleware(async sub ($c, $next) {
        my $token = $c->header('Authorization') // '';
        if ($token ne 'Bearer secret123') {
            $c->status(401);
            return { detail => 'Unauthorized' };
        }
        $c->stash->{user} = 'alice';
        return await $next->($c);
    });

    $app->get('/secure', handler => async sub ($c) {
        return { user => $c->stash->{user} };
    });

    # 1. Missing Token (401)
    my $unauth = run_pagi_request($app, '/secure')->get;
    is $unauth->{status}, 401, 'Rejects with 401 on missing token';
    is $unauth->{json}{detail}, 'Unauthorized', 'Error message returned';

    # 2. Valid Token (200)
    my $auth = run_pagi_request($app, '/secure', 'GET', [['Authorization', 'Bearer secret123']])->get;
    is $auth->{status}, 200, 'Accepts valid token';
    is $auth->{json}{user}, 'alice', 'Stash populated and read by handler';
};

done_testing;
