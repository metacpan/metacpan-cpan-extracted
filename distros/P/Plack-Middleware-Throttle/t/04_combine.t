use strict;
use warnings;
use Test::More;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Throttle::Backend::Hash;

my $handler = builder {
    enable "Throttle::Interval",
        min     => 2,
        backend => Plack::Middleware::Throttle::Backend::Hash->new();
    enable "Throttle::Hourly",
        max     => 4,
        backend => Plack::Middleware::Throttle::Backend::Hash->new();
    enable "Throttle::Daily",
        max     => 6,
        backend => Plack::Middleware::Throttle::Backend::Hash->new();

    sub { [ '200', [ 'Content-Type' => 'text/html' ], ['hello world'] ] };
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        is $res->code, 200, 'http response is 200';
        for ( 1 .. 2 ) {
            my $req = GET "http://localhost/";
            my $res = $cb->($req);
            is $res->code, 503, 'http response is 503';
        }
        sleep(3);
        $req = GET "http://localhost/";
        $res = $cb->($req);
        is $res->code, 200, 'http response is 200';
	sleep(3);
        $req = GET "http://localhost/";
        $res = $cb->($req);
        is $res->code, 503, 'http response is 503';
    }
    };

done_testing;
