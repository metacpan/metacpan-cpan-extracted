#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Plack::Builder;

my $test = sub {
    my ($app, @args) = @_;
    return sub {
        my ($env) = @_;
        my $app = builder {
            enable 'Plack::Middleware::Proxy::Requests', @args;
            $app;
        };
        return $app->($env);
    };
};

{
    my $uri = 'http://example.com/';

    my $env = {
        PATH_INFO         => $uri,
        QUERY_STRING      => '',
        REMOTE_ADDR       => '127.0.0.1',
        REQUEST_METHOD    => 'GET',
        REQUEST_URI       => $uri,
        SCRIPT_NAME       => '',
        SERVER_NAME       => '0',
        SERVER_PORT       => 5000,
        SERVER_PROTOCOL   => 'HTTP/1.1',
        'psgi.url_scheme' => 'http',
        'psgi.version'    => [1, 1],
    };

    my $app_proxy_url = sub {
        [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]->{'plack.proxy.url'} ] ]
    };

    {
        ok my $res = $test->($app_proxy_url)->($env);
        is $res->[2][0], $uri;
    }
}

done_testing;
