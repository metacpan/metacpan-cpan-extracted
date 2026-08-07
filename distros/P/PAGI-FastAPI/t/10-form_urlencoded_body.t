#!/usr/bin/env perl

use v5.36;
use Test::More;
use Future::AsyncAwait;
use JSON::PP qw(decode_json);
use Types::Standard qw(Str Int);
use PAGI::FastAPI;

sub run_request ($pagi_app, %req) {
    my $recv = async sub { return { type => 'http.request', body => $req{body}, more_body => 0 } };
    my ($sent_start, $sent_body);
    my $send = async sub ($event) {
        $sent_start = $event if $event->{type} eq 'http.response.start';
        $sent_body  = $event if $event->{type} eq 'http.response.body';
    };
    $pagi_app->(
        {
            type         => 'http',
            method       => $req{method} // 'POST',
            path         => $req{path},
            query_string => '',
            headers      => $req{content_type} ? [['content-type', $req{content_type}]] : [],
        },
        $recv, $send,
    )->get;
    my $decoded = $sent_body->{body} && length $sent_body->{body} ? eval { decode_json($sent_body->{body}) } : undef;
    return ($sent_start->{status}, $decoded);
}

my $app = PAGI::FastAPI->new(title => 'Form Body Test');
$app->post('/token',
    body    => { username => Str, password => Str },
    handler => async sub ($c) {
        return { username => $c->body('username'), password => $c->body('password') };
    }
);
my $pagi_app = $app->to_app;

subtest 'application/x-www-form-urlencoded body is parsed and validated' => sub {
    my ($status, $data) = run_request($pagi_app,
        path => '/token', content_type => 'application/x-www-form-urlencoded',
        body => 'username=alice&password=wonder+land%21',
    );
    is $status, 200, 'form-encoded POST with a valid body succeeds';
    is $data->{username}, 'alice', 'username field extracted';
    is $data->{password}, 'wonder land!', 'password field extracted and percent-/plus-decoded';
};

subtest 'a Content-Type with charset parameters still matches' => sub {
    my ($status, $data) = run_request($pagi_app,
        path => '/token', content_type => 'application/x-www-form-urlencoded; charset=utf-8',
        body => 'username=bob&password=builder',
    );
    is $status, 200, 'form-encoded body with a charset suffix on Content-Type still parses';
    is $data->{username}, 'bob', 'username field extracted';
};

subtest 'JSON bodies still work exactly as before (backward compatibility)' => sub {
    my ($status, $data) = run_request($pagi_app,
        path => '/token', content_type => 'application/json',
        body => '{"username":"carol","password":"secret"}',
    );
    is $status, 200, 'JSON body with explicit Content-Type still succeeds';
    is $data->{username}, 'carol', 'username field extracted from JSON';
};

subtest 'missing Content-Type still defaults to JSON (backward compatibility)' => sub {
    my ($status, $data) = run_request($pagi_app,
        path => '/token', content_type => undef,
        body => '{"username":"dave","password":"secret"}',
    );
    is $status, 200, 'body with no Content-Type header still parses as JSON';
    is $data->{username}, 'dave', 'username field extracted';
};

subtest 'malformed JSON still 422s (backward compatibility)' => sub {
    my ($status, $data) = run_request($pagi_app,
        path => '/token', content_type => 'application/json',
        body => 'not json{{{',
    );
    is $status, 422, 'malformed JSON body is still rejected with 422';
    is $data->{detail}, 'Invalid JSON body payload', 'the existing error message is unchanged';
};

subtest 'form-encoded body missing a required field is rejected' => sub {
    my ($status, $data) = run_request($pagi_app,
        path => '/token', content_type => 'application/x-www-form-urlencoded',
        body => 'username=eve',
    );
    is $status, 422, 'a form-encoded body missing a required field is rejected with 422';
};

done_testing;
