#!perl -T

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More;

my $app = sub {
    my $env = shift;
    my $body = '';

    [200, ['Content-Type', 'text/plain', 'Content-Length', length($body)], [$body]];
};

$app = builder {
    enable 'HTMLMinify';
    $app;
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/');
    is $res->code, 200;
    is $res->content, '';
};

done_testing;
