#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET POST);

# these are the modules we are testing
use Prancer::Request;
use Prancer::Request::Upload;
use Prancer::Response;

# basic response
{
    my $app = sub {
        my $env = shift;
        my $request = Prancer::Request->new($env);
        my $response = Prancer::Response->new($env);
        return $response->finalize(200);
    };

    test_psgi($app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is($res->code(), 200);
        is($res->content(), '');
        is_deeply([ $res->headers->header_field_names() ], []);
    });
}

# response with headers and cookies
{
    my $app = sub {
        my $env = shift;
        my $request = Prancer::Request->new($env);
        my $response = Prancer::Response->new($env);

        # add some headers
        $response->header("Content-Type" => "text/plain");
        $response->header("Content-Length" => 1234, "X-Foo" => "bar");
        $response->header("X-Bar" => "foo");

        # remove a header
        $response->headers->remove("X-Bar");

        # add some cookies
        $response->cookie("foo1" => {
            'value'    => "test",
            'path'     => "/",
            'domain'   => ".example.com",
            'expires'  => 0 + 24 * 60 * 60,
        });
        $response->cookie("foo2" => {
            'value'    => "test",
            'path'     => "/",
            'domain'   => ".example.com",
            'expires'  => 0 + 24 * 60 * 60,
            'httponly' => 1,
            'secure'   => 1,
        });
        $response->cookie("foo3" => {
            'value'    => "test",
        });

        return $response->finalize(200);
    };

    test_psgi($app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is($res->code(), 200);
        is($res->content(), '');

        is_deeply([ sort $res->headers->header_field_names() ], [ 'Content-Length', 'Content-Type', 'Set-Cookie', 'X-Foo' ]);
        is($res->headers->header('X-Foo'), 'bar');
        is($res->headers->header('Content-Length'), 1234);

        is_deeply([ sort $res->headers->header('Set-Cookie') ], [
            'foo1=test; domain=.example.com; path=/; expires=Fri, 02-Jan-1970 00:00:00 GMT',
            'foo2=test; domain=.example.com; path=/; expires=Fri, 02-Jan-1970 00:00:00 GMT; secure; HttpOnly',
            'foo3=test',
        ]);
    });
}

# response with static body
{
    my $app = sub {
        my $env = shift;
        my $request = Prancer::Request->new($env);
        my $response = Prancer::Response->new($env);
        $response->body("Hello, world!");
        return $response->finalize(200);
    };

    test_psgi($app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is($res->code(), 200);
        is($res->content(), 'Hello, world!');
        is_deeply([ $res->headers->header_field_names() ], []);
    });
}

# response with callback
{
    my $app = sub {
        my $env = shift;
        my $request = Prancer::Request->new($env);
        my $response = Prancer::Response->new($env);

        $response->body(sub {
            my $writer = shift;
            $writer->write("Goodbye, world!");
            $writer->close();
        });

        # need to remove the arrayref from the response
        # the arrayref is there for Web::Simple but breaks everything else
        my $output = $response->finalize(200);
        ok(ref($output));
        is(ref($output), 'ARRAY');
        is(scalar(@{$output}), 1);
        return $output->[0];
    };

    test_psgi($app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is($res->code(), 200);
        is($res->content(), 'Goodbye, world!');
        is_deeply([ $res->headers->header_field_names() ], []);
    });
}

done_testing();
