use strict;
use warnings;
use Test::More;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Throttle::Backend::Hash;

my $handler = builder {
    enable "Throttle::Hourly",
        max     => 1,
        backend => Plack::Middleware::Throttle::Backend::Hash->new(),
        path    => qr{^/api};
    sub { [ '200', [ 'Content-Type' => 'text/html' ], ['hello world'] ] };
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        for ( 1 .. 2 ) {
            my $req = GET "http://localhost/bar";
            my $res = $cb->($req);
            is $res->content, 'hello world', 'content is valid';
            ok !$res->header('X-RateLimit-Limit'), 'no header ratelimit';
        }
        my $req = GET "http://localhost/api";
        my $res = $cb->($req);
        is $res->content, 'hello world', 'content is valid';
        ok $res->header('X-RateLimit-Limit'), 'header ratelimit';
        $req = GET "http://localhost/api";
        $res = $cb->($req);
        is $res->code, 503, 'rate limit exceeded';
    }
};

done_testing;
