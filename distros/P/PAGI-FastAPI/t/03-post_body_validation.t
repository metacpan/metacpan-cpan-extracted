#!/usr/bin/env perl

use v5.38;
use Test::More;
use Future::AsyncAwait;
use JSON::PP qw(encode_json decode_json);
use Types::Standard qw(Int Str Dict);
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new();

# HashRef Spec
$app->post('/items',
    body    => { name => Str, quantity => Int },
    handler => async sub ($c) {
        return { created => 1, item => $c->body };
    }
);

# Dict Spec
$app->post('/users',
    body    => Dict[ username => Str, age => Int ],
    handler => async sub ($c) {
        return { user_created => 1, user => $c->body };
    }
);

my $pagi_app = $app->to_app;

async sub run_pagi_request ($path, $body_payload, $method = 'POST') {
    my $response_status;
    my %response_headers;
    my $response_body = '';

    my $scope = {
        type   => 'http',
        method => $method,
        path   => $path,
    };

    my $sent = 0;
    my $receive = async sub {
        return { type => 'http.request', body => $body_payload, more_body => 0 } if $sent++ == 0;
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

    await $pagi_app->($scope, $receive, $send);

    my $json = eval { decode_json($response_body) };
    return { status => $response_status, body => $response_body, json => $json };
}

subtest 'Valid POST with HashRef body' => sub {
    my $res = run_pagi_request('/items', encode_json({ name => 'Widget', quantity => 10 }))->get;
    is $res->{status}, 200, 'Status is 200';
    is $res->{json}{created}, 1, 'Created flag returned';
    is $res->{json}{item}{name}, 'Widget', 'Payload echoed correctly';
};

subtest 'Invalid POST field type (422 Unprocessable Entity)' => sub {
    my $res = run_pagi_request('/items', encode_json({ name => 'Widget', quantity => 'not_a_number' }))->get;
    is $res->{status}, 422, 'Status is 422';
    like $res->{json}{detail}, qr/quantity/, 'Error details mention failing field';
};

subtest 'Valid POST with Type::Tiny Dict spec' => sub {
    my $res = run_pagi_request('/users', encode_json({ username => 'alice', age => 30 }))->get;
    is $res->{status}, 200, 'Status is 200';
    is $res->{json}{user}{username}, 'alice', 'User created';
};

subtest 'Invalid Malformed JSON Payload (422 Unprocessable Entity)' => sub {
    my $res = run_pagi_request('/items', '{ bad_json: ')->get;
    is $res->{status}, 422, 'Status is 422';
    is $res->{json}{detail}, 'Invalid JSON body payload', 'Catches bad JSON cleanly';
};

done_testing;
