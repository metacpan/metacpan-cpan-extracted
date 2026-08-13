#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use JSON::PP qw(encode_json decode_json);
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);

my $app = PAGI::FastAPI->new();

# Async Dependency 1: Simulated Database Connection
my $get_db = async sub ($c) {
    return { connection => 'active_db_pool' };
};

# Async Dependency 2: Auth Verification
my $get_user = async sub ($c) {
    my $token = $c->header('Authorization') // '';
    if ($token ne 'Bearer valid_token') {
        $c->status(401);
        return { detail => 'Unauthorized token' };
    }
    return { id => 101, username => 'alice', role => 'admin' };
};

# Route using HashRef Dependency syntax
$app->get('/dashboard',
    dependencies => {
        db   => $get_db,
        user => $get_user,
    },
    handler => async sub ($c) {
        return {
            user => $c->stash->{user}{username},
            db   => $c->stash->{db}{connection},
        };
    }
);

# Route using Depends() syntax with sequential guard check
$app->get('/admin/secret',
    dependencies => [
        Depends($get_user, key => 'user'),
        async sub ($c) {
            if ($c->stash->{user}{role} ne 'admin') {
                $c->status(403);
                return { detail => 'Forbidden' };
            }
        },
    ],
    handler => async sub ($c) {
        return { secret => 'top_secret_value' };
    }
);

# Helper runner
async sub run_pagi_request ($path, $headers = []) {
    my $response_status;
    my %response_headers;
    my $response_body = '';

    my $scope = {
        type    => 'http',
        method  => 'GET',
        path    => $path,
        headers => $headers,
    };

    my $sent = 0;
    my $receive = async sub {
        return { type => 'http.request', body => '', more_body => 0 } if $sent++ == 0;
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

subtest 'Dependency Injection with HashRef' => sub {
    # 1. Unauthenticated -> 401 Unauthorized
    my $unauth = run_pagi_request('/dashboard')->get;
    is $unauth->{status}, 401, '401 returned when auth dependency fails';
    is $unauth->{json}{detail}, 'Unauthorized token', 'Error details passed back';

    # 2. Authenticated -> Dependencies injected into stash
    my $auth = run_pagi_request('/dashboard', [['Authorization', 'Bearer valid_token']])->get;
    is $auth->{status}, 200, '200 returned when dependencies pass';
    is $auth->{json}{user}, 'alice', 'User dependency injected into stash';
    is $auth->{json}{db}, 'active_db_pool', 'DB dependency injected into stash';
};

subtest 'Sequential Guard Dependencies using Depends()' => sub {
    my $res = run_pagi_request('/admin/secret', [['Authorization', 'Bearer valid_token']])->get;
    is $res->{status}, 200, '200 returned when user passes guard check';
    is $res->{json}{secret}, 'top_secret_value', 'Handler executed';
};

done_testing;
