use strict;
use warnings;
use Test::More;
use HTTP::Request;
use Plack::Builder;
use Plack::Test;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello'] ];
};

$app = builder {
    enable 'ChromeFrame';
    $app;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = HTTP::Request->new(GET => '/');
    my $res = $cb->($req);
    is $res->code, 200;
    is $res->content, 'Hello';

    $req->header(
        user_agent => 'Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 6.0)',
    );
    $res = $cb->($req);
    is $res->code, 302;
    is $res->content, '';

    $req->header(
        user_agent => 'Mozilla/4.0 (compatible; MSIE 7.0b; chromeframe=1)',
    );
    $res = $cb->($req);
    is $res->code, 200;
    is $res->content, 'Hello';
    is $res->header('x_ua_compatible'), 'chrome=1';

    $req->header(
        user_agent => 'Mozilla/4.0 (compatible; MSIE 6.0) Opera 8.50',
    );
    $res = $cb->($req);
    is $res->code, 200;
    is $res->content, 'Hello';
    ok not $res->header('x_ua_compatible');
};

done_testing;
