#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Request;

# Helper to create a mock receive that returns body in chunks
sub mock_receive {
    my (@chunks) = @_;
    my $index = 0;
    return async sub {
        if ($index < @chunks) {
            my $chunk = $chunks[$index++];
            return {
                type => 'http.request',
                body => $chunk,
                more => ($index < @chunks),
            };
        }
        return { type => 'http.disconnect' };
    };
}

subtest 'body reads entire content' => sub {
    my $scope = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-length', '11']],
    };
    my $receive = mock_receive('Hello', ' ', 'World');
    my $req = PAGI::Request->new($scope, $receive);

    my $body = (async sub { await $req->body })->();
    $body = $body->get;  # Resolve Future

    is($body, 'Hello World', 'body concatenates all chunks');
};

subtest 'body caches result' => sub {
    my $call_count = 0;
    my $scope = { type => 'http', method => 'POST', headers => [] };
    my $receive = async sub {
        $call_count++;
        return { type => 'http.request', body => 'data', more => 0 };
    };

    my $req = PAGI::Request->new($scope, $receive);

    my $body1 = (async sub { await $req->body })->()->get;
    my $body2 = (async sub { await $req->body })->()->get;

    is($body1, 'data', 'first read works');
    is($body2, 'data', 'second read works');
    is($call_count, 1, 'receive only called once (cached)');
};

subtest 'text decodes as UTF-8' => sub {
    my $utf8_bytes = "Caf\xc3\xa9";  # "Café" in UTF-8
    my $scope = { type => 'http', method => 'POST', headers => [] };
    my $receive = mock_receive($utf8_bytes);
    my $req = PAGI::Request->new($scope, $receive);

    my $text = (async sub { await $req->text })->()->get;

    is($text, "Café", 'text decodes UTF-8');
};

subtest 'json parses body' => sub {
    my $json_body = '{"name":"John","age":30}';
    my $scope = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/json']],
    };
    my $receive = mock_receive($json_body);
    my $req = PAGI::Request->new($scope, $receive);

    my $data = (async sub { await $req->json })->()->get;

    is($data, { name => 'John', age => 30 }, 'json parses correctly');
};

subtest 'json dies on invalid JSON' => sub {
    my $bad_json = '{"broken":';
    my $scope = { type => 'http', method => 'POST', headers => [] };
    my $receive = mock_receive($bad_json);
    my $req = PAGI::Request->new($scope, $receive);

    my $died = 0;
    eval {
        (async sub { await $req->json })->()->get;
    };
    $died = 1 if $@;

    ok($died, 'json dies on invalid JSON');
};

subtest 'empty body' => sub {
    my $scope = { type => 'http', method => 'GET', headers => [] };
    my $receive = mock_receive();
    my $req = PAGI::Request->new($scope, $receive);

    my $body = (async sub { await $req->body })->()->get;

    is($body, '', 'empty body returns empty string');
};

done_testing;
