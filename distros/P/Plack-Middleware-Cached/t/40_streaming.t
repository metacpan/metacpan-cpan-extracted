use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Cached;
use HTTP::Request::Common;

use lib 't/';
require 'mock-cache';

my $cache = Mock::Cache->new;

my $counter = 1;

my $capp = sub {
    my ($app, @args) = @_;
    builder {
        enable 'Cached', cache => $cache, @args;
        $app;
    };
};


my $app_static = sub {
    my ($env) = @_;
    $env->{counter} = $counter;
    [ 200, [ 'Content-Type' => 'text/plain' ], [ $counter++ ] ]
};

test_psgi $capp->($app_static), sub {
    my $cb = shift;

    my $res = $cb->(GET "/a");
    is $res->code, 200;
    is $res->content, 1;
} foreach (1..2);


my $app_delayed = sub {
    my ($app) = @_;
    return sub {
        my ($env) = @_;
        return sub {
            my ($responder) = @_;
            $responder->( $app->() );
        };
    };
};

test_psgi $capp->($app_delayed->($app_static)), sub {
    my $cb = shift;

    my $res = $cb->(GET "/b");
    is $res->code, 200;
    is $res->content, 2;
} foreach (1..2);


my $app_streaming = sub {
    return sub {
        my ($responder) = @_;
        my $writer = $responder->(
            [ 200, [ 'Content-Type' => 'text/plain' ] ]
        );
        $writer->write($counter);
        $writer->write($counter);
        $writer->close;
        return;
    };
};

test_psgi $capp->($app_streaming), sub {
    my $cb = shift;

    my $res = $cb->(GET "/c");
    is $res->code, 200;
    is $res->content, 33;
} foreach (1..2);


done_testing;
