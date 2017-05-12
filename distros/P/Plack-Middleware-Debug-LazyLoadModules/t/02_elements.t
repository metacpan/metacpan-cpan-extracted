#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use Plack::Util;
use HTTP::Request::Common;
use Test::More;
use lib 't/lib';

{
    my $app = sub {
        Plack::Util::load_class("+LazyWay", "Foo");
        return [
            200,
            [ 'Content-Type' => 'text/html' ],
            ['<html><body>Be Lazy!</body></html>']
        ];
    };

    $app = builder {
        enable 'Debug', panels => [
            [ 'LazyLoadModules', elements => [qw/preload/] ]
        ];
        $app;
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        unlike $res->content,
          qr{<h3>Lazy</h3>},
          "not include lazy panel";
    };
}

{
    my $app = sub {
        Plack::Util::load_class("+LazyWay2", "Bar");
        return [
            200,
            [ 'Content-Type' => 'text/html' ],
            ['<html><body>Be Lazy!</body></html>']
        ];
    };

    $app = builder {
        enable 'Debug', panels => [
            [ 'LazyLoadModules', elements => [qw/lazy/] ]
        ];
        $app;
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content,
          qr{<small>1/\d+ lazy loaded</small>},
          "loaded count";

        unlike $res->content,
          qr{<h3>Preload</h3>},
          "not include preload panel";
    };

}

done_testing;