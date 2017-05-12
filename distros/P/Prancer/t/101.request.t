#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET POST);

# these are the modules we are testing
use Prancer::Request;
use Prancer::Request::Upload;
use Prancer::Response;

{
    # test basic methods with a GET
    my $req = Prancer::Request->new({
          'HTTP_ACCEPT' => 'text/html, text/plain, text/css, text/sgml, */*;q=0.01',
          'HTTP_ACCEPT_ENCODING' => 'gzip, compress, bzip2',
          'HTTP_ACCEPT_LANGUAGE' => 'en',
          'HTTP_HOST' => 'localhost:5000',
          'HTTP_USER_AGENT' => 'Lynx/2.8.8dev.12 libwww-FM/2.14 SSL-MM/1.4.1 GNUTLS/2.12.18',
          'HTTP_X_MYHEADER' => '123, 321',
          'PATH_INFO' => '/asdf',
          'QUERY_STRING' => '',
          'REMOTE_USER' => 'foobar',
          'REMOTE_ADDR' => '127.0.0.1',
          'REMOTE_PORT' => 41049,
          'REQUEST_METHOD' => 'GET',
          'REQUEST_URI' => '/asdf',
          'SCRIPT_NAME' => '',
          'SERVER_NAME' => 0,
          'SERVER_PORT' => 5000,
          'SERVER_PROTOCOL' => 'HTTP/1.0',
          'psgi.input' => undef,
          'psgi.errors' => undef,
          'psgi.multiprocess' => '',
          'psgi.multithread' => '',
          'psgi.nonblocking' => '',
          'psgi.run_once' => '',
          'psgi.streaming' => 1,
          'psgi.url_scheme' => 'http',
          'psgi.version' => [ 1, 1 ],
          'psgix.harakiri' => 1,
          'psgix.input.buffered' => 1,
    });

    isa_ok($req, 'Prancer::Request');
    is($req->uri(), 'http://localhost:5000/asdf');
    is($req->base(), 'http://localhost:5000/');
    is($req->method(), 'GET');
    is($req->protocol(), 'HTTP/1.0');
    is($req->scheme(), 'http');
    is($req->port(), 5000);
    is($req->secure(), 0);
    is($req->path(), '/asdf');
    is($req->body(), undef);
    is($req->address(), '127.0.0.1');
    is($req->user(), 'foobar');

    is($req->uri_for('fdsa'), 'http://localhost:5000/fdsa');
    is($req->uri_for('/fdsa'), 'http://localhost:5000/fdsa');
    is($req->uri_for('/logout', [ signoff => 1 ]), 'http://localhost:5000/logout?signoff=1');
}

# most of Prancer::Request and Prancer::Request::Upload are implemented by
# Plack and Prancer just proxies the requests through. However, Prancer does
# implement some of its own logic for:
#  - params
#  - cookies
#  - uploads
#  - upload basename

# test params, cookies
{
    my $req = Prancer::Request->new({
          'HTTP_COOKIE' => 'USER_TOKEN=Yes',
          'HTTP_ACCEPT' => 'text/html, text/plain, text/css, text/sgml, */*;q=0.01',
          'HTTP_ACCEPT_ENCODING' => 'gzip, compress, bzip2',
          'HTTP_ACCEPT_LANGUAGE' => 'en',
          'HTTP_HOST' => 'localhost:5000',
          'HTTP_USER_AGENT' => 'Lynx/2.8.8dev.12 libwww-FM/2.14 SSL-MM/1.4.1 GNUTLS/2.12.18',
          'PATH_INFO' => '/asdf',
          'REMOTE_ADDR' => '127.0.0.1',
          'REMOTE_PORT' => 41049,
          'REQUEST_METHOD' => 'GET',
          'QUERY_STRING' => 'foo=bar&baz=bat&qwerty=fdsa&qwerty=asdf',
          'REQUEST_URI' => '/index?foo=bar&baz=bat&qwerty=fdsa&qwerty=asdf',
          'SCRIPT_NAME' => '',
          'SERVER_NAME' => 0,
          'SERVER_PORT' => 5000,
          'SERVER_PROTOCOL' => 'HTTP/1.0',
          'psgi.input' => undef,
          'psgi.errors' => undef,
          'psgi.multiprocess' => '',
          'psgi.multithread' => '',
          'psgi.nonblocking' => '',
          'psgi.run_once' => '',
          'psgi.streaming' => 1,
          'psgi.url_scheme' => 'http',
          'psgi.version' => [ 1, 1 ],
          'psgix.harakiri' => 1,
          'psgix.input.buffered' => 1,
    });

    {
        my @keys = $req->param();
        is_deeply([ sort @keys ], [ 'baz', 'foo', 'qwerty' ]);

        my $keys = $req->param();
        is($keys, 3);

        is($req->param('foo'), 'bar');
        is($req->param('baz'), 'bat');

        my @multivalue = $req->param('qwerty');
        is_deeply([ sort @multivalue ], [ 'asdf', 'fdsa' ]);

        my $multivalue = $req->param('qwerty');
        is($multivalue, 'asdf');
    }

    {
        my @keys = $req->cookie();
        is_deeply([ sort @keys ], [ 'USER_TOKEN' ]);

        my $keys = $req->cookie();
        is($keys, 1);

        is($req->cookie('USER_TOKEN'), 'Yes');

        my @multivalue = $req->cookie('USER_TOKEN');
        is_deeply([ sort @multivalue ], [ 'Yes' ]);

        my $multivalue = $req->cookie('USER_TOKEN');
        is($multivalue, 'Yes');
    }
}

# test posts with args
{
    my $app = sub {
        my $env = shift;
        my $request = Prancer::Request->new($env);
        my $response = Prancer::Response->new($env);

        is($request->param('foo'), 'bar');
        is($request->content(), 'foo=bar');

        return $response->finalize(200);
    };

    test_psgi($app, sub {
        my $cb = shift;
        my $res = $cb->(POST "/", { foo => "bar" });
        ok($res->is_success());
    });
}

# test uploads
{
    my $app = sub {
        my $env = shift;
        my $request = Prancer::Request->new($env);
        my $response = Prancer::Response->new($env);

        my @keys = $request->upload();
        is_deeply([ sort @keys ], [ 'bar', 'foo' ]);

        my $keys = $request->upload();
        is($keys, 2);

        my $single = $request->upload('bar');
        isa_ok($single, 'Prancer::Request::Upload');
        is($single->filename(), 'foo1.txt');
        is($single->size(), 5);
        is($single->content_type(), 'text/plain');

        my @multi = $request->upload('foo');
        isa_ok($_, 'Prancer::Request::Upload') for (@multi);

        return $response->finalize(200);
    };

    test_psgi($app, sub {
        my $cb = shift;

        my $res = $cb->(POST "/", Content_Type => 'form-data', Content => [
             'foo' => [ "t/foo1.txt" ],
             'foo' => [ "t/foo2.txt" ],
             'bar' => [ "t/foo1.txt" ],
        ]);

        ok($res->is_success());
    });
}

done_testing();
