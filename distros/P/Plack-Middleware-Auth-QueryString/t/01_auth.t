use strict;
use warnings;

use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

{
    my $app = sub {
        return [200, ['Content-Type' => 'text/plain'], ['Hello World']];
    };

    $app = builder {
        enable 'Plack::Middleware::Auth::QueryString',
            password    => 'hoge'
        ;
        $app;
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET 'http://localhost/');
        is $res->code, 401;

        $res = $cb->(GET 'http://localhost/?key=fuga');
        is $res->code, 401;

        $res = $cb->(GET 'http://localhost/?key=hoge');
        is $res->code,    200;
        is $res->content, "Hello World";

        $res = $cb->(GET 'http://localhost/?key=hoge&piyo=aaaaaa');
        is $res->code,    200;
        is $res->content, "Hello World";
    };
}

{
    my $app = sub {
        return [200, ['Content-Type' => 'text/plain'], ['Hello World']];
    };

    $app = builder {
        enable 'Plack::Middleware::Auth::QueryString',
            key => 'access_token',
            password    => 'hogefuga'
        ;
        $app;
    };

    test_psgi $app, sub {
        my $cb  = shift;

        my $res = $cb->(GET 'http://localhost/?key=hogefuga');
        is $res->code, 401;

        $res = $cb->(GET 'http://localhost/?access_token=fuga');
        is $res->code, 401;

        $res = $cb->(GET 'http://localhost/?access_token=hogefuga');
        is $res->code,    200;
        is $res->content, "Hello World";
    };
}

done_testing;

