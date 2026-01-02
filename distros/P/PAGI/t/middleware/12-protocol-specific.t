#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;

use PAGI::Middleware::SSE::Retry;

my $loop = IO::Async::Loop->new;

sub run_async (&) {
    my ($code) = @_;
    $loop->await($code->());
}

# ===================
# SSE::Retry Tests
# ===================

subtest 'SSE::Retry - sends retry hint on start' => sub {
    my $retry = PAGI::Middleware::SSE::Retry->new(
        retry => 5000,
        include_on_start => 1,
    );

    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'sse.start' });
        await $send->({ type => 'sse.send', data => 'test' });
    };

    my $wrapped = $retry->wrap($app);
    my $scope = { type => 'sse', headers => [] };

    my @events;
    run_async {
        $wrapped->($scope, async sub { {} }, async sub  {
        my ($e) = @_; push @events, $e });
    };

    is scalar(@events), 3, 'three events sent';
    is $events[0]{type}, 'sse.start', 'first is sse.start';
    is $events[1]{type}, 'sse.send', 'second is retry hint';
    is $events[1]{retry}, 5000, 'retry value set';
    is $events[2]{type}, 'sse.send', 'third is data event';
};

subtest 'SSE::Retry - adds retry to scope' => sub {
    my $retry = PAGI::Middleware::SSE::Retry->new(retry => 3000);

    my $captured_scope;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;
        await $send->({ type => 'sse.start' });
    };

    my $wrapped = $retry->wrap($app);
    my $scope = { type => 'sse', headers => [] };

    run_async { $wrapped->($scope, async sub { {} }, async sub { }) };

    is $captured_scope->{'pagi.sse.retry'}, 3000, 'retry in scope';
};

subtest 'SSE::Retry - passes through non-SSE' => sub {
    my $retry = PAGI::Middleware::SSE::Retry->new();

    my $captured_scope;
    my $app = async sub  {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my $wrapped = $retry->wrap($app);
    my $scope = { type => 'http', method => 'GET', path => '/' };

    run_async { $wrapped->($scope, async sub { {} }, async sub { }) };

    ok !exists $captured_scope->{'pagi.sse.retry'}, 'no retry for HTTP';
};

done_testing;
