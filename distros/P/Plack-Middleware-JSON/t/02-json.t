#!/usr/bin/perl
use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use HTTP::Request::Common;
use lib './lib';

BEGIN {
    use_ok( 'Plack::Middleware::JSON' ) || print "Bail out!\n";
    eval q{ require HTTP::Request::Common } or plan skip_all => 'Could not require HTTP::Request::Common';
}

my $app = builder {
    enable sub {
        my $app = shift;
    };
    enable 'Plack::Middleware::JSON', 
        json_key => 'json';
    sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ { test => 'ok' } ] ] };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/?json=1');
    is $res->content, '{"test":"ok"}';
};



$app = builder {
    enable sub {
        my $app = shift;
    };
    enable 'Plack::Middleware::JSON', 
        json_key => 'jsonp';
    sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ { test => 'ok' } ] ] };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/?jsonp=1');
    is $res->content, '{"test":"ok"}';
};



$app = builder {
    enable sub {
        my $app = shift;
    };
    enable 'Plack::Middleware::JSON', 
        callback_key => 'test';
    sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ { test => 'ok' } ] ] };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/?test=fukai');
    is $res->content, 'fukai({"test":"ok"})';
};


$app = builder {
    enable sub {
        my $app = shift;
    };
    enable 'Plack::Middleware::JSON';
    sub { return [ 200, [ 'Content-Type' => 'text/json' ], [ { test => 'ok' } ] ] };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is $res->content, '{"test":"ok"}';
};

done_testing;

