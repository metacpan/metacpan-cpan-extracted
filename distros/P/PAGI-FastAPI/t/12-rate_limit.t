#!/usr/bin/env perl

use v5.38;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new(title => 'Rate Limit Test');

# App-level rate limiting: 3 requests per 60 seconds
$app->add_rate_limit(
    requests => 3,
    window   => 60,
    key_cb   => sub ($c) { return $c->header('X-API-Key') // 'default-client' },
);

$app->get('/test' => handler => async sub ($c) {
    return { status => 'ok' };
});

my $pagi_fn = $app->to_app;

async sub call_app ($key) {
    my %res_data;
    my $scope = {
        type    => 'http',
        method  => 'GET',
        path    => '/test',
        headers => [['x-api-key', $key]],
        client  => ['127.0.0.1', 12345],
    };

    my $send = async sub ($msg) {
        if ($msg->{type} eq 'http.response.start') {
            $res_data{status}  = $msg->{status};
            $res_data{headers} = { map { $_->[0] => $_->[1] } @{$msg->{headers}} };
        } elsif ($msg->{type} eq 'http.response.body') {
            $res_data{body} = $msg->{body};
        }
    };

    my $receive = async sub { return { type => 'http.disconnect' } };

    await $pagi_fn->($scope, $receive, $send);
    return \%res_data;
}

subtest 'Rate limiter limits requests after threshold' => sub {
    for my $i (1..3) {
        my $res = call_app('client-A')->get;
        is($res->{status}, 200, "Request $i succeeded");
    }

    my $blocked = call_app('client-A')->get;
    is($blocked->{status}, 429, '4th request blocked with 429');
    ok(exists $blocked->{headers}{'retry-after'}, 'Retry-After header present');
};

subtest 'Separate client keys maintain independent quotas' => sub {
    my $res = call_app('client-B')->get;
    is($res->{status}, 200, 'Separate key client-B gets fresh quota');
};

done_testing();
