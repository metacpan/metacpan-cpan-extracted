#!perl -T

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More;

my $body = [''];

my $app = sub {
    my $env = shift;

    [200, ['Content-Type', 'text/plain', 'Content-Length', length(join '', $body)], $body];
};

$app = builder {
    enable 'HTMLMinify';
    $app;
};

test_psgi $app, sub {
    my $cb = shift;

    $body = ['<html>', '</html>'];
    my $res = $cb->(GET '/');
    is $res->code, 200;
    is $res->content, '<html></html>';
};

done_testing;
