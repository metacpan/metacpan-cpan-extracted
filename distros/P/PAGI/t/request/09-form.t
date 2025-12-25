#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Request;

sub mock_receive {
    my (@chunks) = @_;
    my $index = 0;
    return async sub {
        if ($index < @chunks) {
            my $chunk = $chunks[$index++];
            return { type => 'http.request', body => $chunk, more => ($index < @chunks) };
        }
        return { type => 'http.disconnect' };
    };
}

subtest 'form parses urlencoded' => sub {
    my $body = 'name=John%20Doe&email=john%40example.com&tags=perl&tags=async';
    my $scope = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/x-www-form-urlencoded']],
    };
    my $receive = mock_receive($body);
    my $req = PAGI::Request->new($scope, $receive);

    my $form = (async sub { await $req->form })->()->get;

    isa_ok $form, 'Hash::MultiValue';
    is($form->get('name'), 'John Doe', 'name decoded');
    is($form->get('email'), 'john@example.com', 'email decoded');

    my @tags = $form->get_all('tags');
    is(\@tags, ['perl', 'async'], 'multi-value works');
};

subtest 'form with UTF-8' => sub {
    my $body = 'message=%E4%BD%A0%E5%A5%BD';  # 你好 URL-encoded
    my $scope = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/x-www-form-urlencoded']],
    };
    my $receive = mock_receive($body);
    my $req = PAGI::Request->new($scope, $receive);

    my $form = (async sub { await $req->form })->()->get;

    is($form->get('message'), '你好', 'UTF-8 decoded');
};

subtest 'form caches result' => sub {
    my $call_count = 0;
    my $scope = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/x-www-form-urlencoded']],
    };
    my $receive = async sub {
        $call_count++;
        return { type => 'http.request', body => 'x=1', more => 0 };
    };
    my $req = PAGI::Request->new($scope, $receive);

    (async sub { await $req->form })->()->get;
    (async sub { await $req->form })->()->get;

    is($call_count, 1, 'receive only called once');
};

subtest 'empty form' => sub {
    my $scope = {
        type    => 'http',
        method  => 'POST',
        headers => [['content-type', 'application/x-www-form-urlencoded']],
    };
    my $receive = mock_receive('');
    my $req = PAGI::Request->new($scope, $receive);

    my $form = (async sub { await $req->form })->()->get;

    isa_ok $form, 'Hash::MultiValue';
    is([$form->keys], [], 'empty form has no keys');
};

done_testing;
