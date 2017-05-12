use strict;
use warnings;
use Test::More tests => 10;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'hello world' ] ];
};

my $handler = builder {
    enable 'LimitRequest', body => 100;
    $app;
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        ok $res->is_success;
        ok $res->code == 200;
        is $res->content, 'hello world';
    };

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => 'http://localhost/', [], 'x');
        my $res = $cb->($req);
        ok $res->is_success;
        ok $res->code == 200;
        is $res->content, 'hello world';
    };

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $req =
            HTTP::Request->new(POST => 'http://localhost/', [], 'x' x 101);
        my $res = $cb->($req);
        ok ! $res->is_success;
        ok $res->code != 200;
        ok $res->code == 413;
        isnt $res->content, 'hello world';
    };
