#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use PAGI::FastAPI;
use PAGI::FastAPI::RateLimit::Driver::Memory;

my $key_cb       = sub ($c) { return $c->header('X-API-Key') // 'default-client' };
my $app_driver   = PAGI::FastAPI::RateLimit::Driver::Memory->new;
my $route_driver = PAGI::FastAPI::RateLimit::Driver::Memory->new;

my $app = PAGI::FastAPI->new(title => 'Stacked Rate Limit Test');

# App-wide: 5 requests / 60s, applied manually:
# mirrors eg/rate_limit_demo.pl rather than add_rate_limit(), purely so this
# test can reach the driver directly for the reset_async() assertions below.

my $app_wide_limiter = PAGI::FastAPI::Middleware::RateLimit->new(
    requests => 5,
    window   => 60,
    key_cb   => $key_cb,
    driver   => $app_driver,
);

$app->add_middleware(async sub ($c, $next) {
    return await $app_wide_limiter->handle($c, $next);
});

$app->get('/cheap', handler => async sub ($c) {
    return { ok => 1, endpoint => 'cheap' };
});

# Route-level: 2 requests / 60s, stacked on top of the app-wide limiter.
$app->get('/expensive',
    rate_limit => {
        requests => 2,
        window   => 60,
        key_cb   => $key_cb,
        driver   => $route_driver,
    },
    handler => async sub ($c) {
        return { ok => 1, endpoint => 'expensive' };
    }
);

my $pagi_fn = $app->to_app;

async sub call_app ($path, $key) {
    my %res_data;
    my $scope = {
        type    => 'http',
        method  => 'GET',
        path    => $path,
        headers => [['x-api-key', $key]],
        client  => ['127.0.0.1', 12345],
    };

    my $send = async sub ($msg) {
        if ($msg->{type} eq 'http.response.start') {
            $res_data{status} = $msg->{status};
            # Keep the RAW header pairs  (not collapsed into a hash) so
            # duplicate x-ratelimit-* entries from stacked limiters are
            # visible, collapsing into a hash would silently drop all
            # but the last value for a repeated header name.
            $res_data{raw_headers} = $msg->{headers};
        }
        elsif ($msg->{type} eq 'http.response.body') {
            $res_data{body} = $msg->{body};
        }
    };

    my $receive = async sub { return { type => 'http.disconnect' } };

    await $pagi_fn->($scope, $receive, $send);
    return \%res_data;
}

sub header_values ($res, $name) {
    my $lc = lc($name);
    return [
        map  { $_->[1] }
        grep { lc($_->[0]) eq $lc } @{ $res->{raw_headers} } ];
}

subtest 'Route with only the app-wide limiter gets one set of headers' => sub {
    my $res = call_app('/cheap', 'client-single')->get;
    is($res->{status}, 200, 'cheap request succeeds');
    is(scalar @{ header_values($res, 'x-ratelimit-limit') }, 1,
        'exactly one x-ratelimit-limit header on a route with no per-route limiter');
    is(header_values($res, 'x-ratelimit-limit')->[0], 5, 'reflects the app-wide limit (5)');
};

subtest 'Route with both limiters gets two independent sets of headers' => sub {
    my $res = call_app('/expensive', 'client-stacked')->get;
    is($res->{status}, 200, 'expensive request succeeds');

    my $limits = header_values($res, 'x-ratelimit-limit');
    is(scalar @$limits, 2, 'two x-ratelimit-limit headers present (app-wide + route)');

    # add_header appends in call order; the app-wide middleware wraps
    # outermost and runs first, so [0] is app-wide, [1] is the route's own.
    is($limits->[0], 5, 'first x-ratelimit-limit is the app-wide budget (5)');
    is($limits->[1], 2, 'second x-ratelimit-limit is the route budget (2)');
};

subtest 'Route-level budget blocks independently of the app-wide budget' => sub {
    my $key = 'client-independent';

    # Exhaust the 2-request route-level budget for /expensive.
    for my $i (1 .. 2) {
        my $res = call_app('/expensive', $key)->get;
        is($res->{status}, 200, "expensive request $i within route budget succeeds");
    }

    my $blocked = call_app('/expensive', $key)->get;
    is($blocked->{status}, 429, '3rd /expensive request blocked by the route-level budget');
    ok(scalar(@{ header_values($blocked, 'retry-after') }), 'retry-after header present when blocked');

    # App-wide budget (5/60s) only saw 3 requests so far for this key,
    # still well within quota, so /cheap must still succeed.
    my $cheap = call_app('/cheap', $key)->get;
    is($cheap->{status}, 200,
        '/cheap still succeeds for the same client, app-wide budget is a separate counter, unaffected by /expensive being blocked');
};

subtest 'reset_async() on each driver clears only that budget' => sub {
    my $key = 'client-reset';

    # Exhaust the route-level budget only.
    for (1 .. 2) { call_app('/expensive', $key)->get }
    my $blocked = call_app('/expensive', $key)->get;
    is($blocked->{status}, 429, 'route budget exhausted for this key');

    # Resetting the APP driver should NOT restore the route budget.
    $app_driver->reset_async($key)->get;
    my $still_blocked = call_app('/expensive', $key)->get;
    is($still_blocked->{status}, 429,
        'resetting the app-wide driver alone does not clear the independent route-level budget');

    # Resetting the ROUTE driver restores it.
    $route_driver->reset_async($key)->get;
    my $restored = call_app('/expensive', $key)->get;
    is($restored->{status}, 200, 'resetting the route driver restores the route-level budget');
};

done_testing;
