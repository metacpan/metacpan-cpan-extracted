#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Path::Class;
use Plack::Builder;

my $data_root = file(__FILE__)->dir->subdir('data', '02');

{
    my $app = builder {
        enable 'Auth::Htpasswd',
            file_root => $data_root->subdir('foo');
        sub {
            [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ "Hello $_[0]->{REMOTE_USER}: $_[0]->{PATH_INFO}" ],
            ]
        };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 401, "plain request gets 401");
        }

        {
            my $res = $cb->(GET "/", 'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 200, "authorized request gets 200");
            is($res->content, 'Hello foo: /', "and gets the right content");
        }

        {
            my $res = $cb->(GET "/bar.txt");
            is($res->code, 401, "plain request gets 401");
        }

        {
            my $res = $cb->(GET "/bar.txt",
                                'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 200, "authorized request gets 200");
            is($res->content, 'Hello foo: /bar.txt',
               "and gets the right content");
        }

        {
            my $res = $cb->(GET "/bar", 'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 200, "authorized request gets 200");
            is($res->content, 'Hello foo: /bar', "and gets the right content");
        }

        {
            my $res = $cb->(GET "/bar/baz.txt",
                                'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 200, "authorized request gets 200");
            is($res->content, 'Hello foo: /bar/baz.txt',
               "and gets the right content");
        }

        {
            my $res = $cb->(GET "/bar/baz",
                                'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 401, "user foo isn't authorized for this path");
        }

        {
            my $res = $cb->(GET "/bar/baz",
                                'Authorization' => 'Basic YmF6OjQzMjE=');
            is($res->code, 200, "but user baz is");
            is($res->content, 'Hello baz: /bar/baz',
               "and gets the right content");
        }

        {
            my $res = $cb->(GET "/bar/baz/quux.txt",
                                'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 401, "user foo isn't authorized for this path");
        }

        {
            my $res = $cb->(GET "/bar/baz/quux.txt",
                                'Authorization' => 'Basic YmF6OjQzMjE=');
            is($res->code, 200, "but user baz is");
            is($res->content, 'Hello baz: /bar/baz/quux.txt',
               "and gets the right content");
        }

        {
            my $res = $cb->(GET "/rab/zab");
            is($res->code, 401, "plain request gets 401");
        }

        {
            my $res = $cb->(GET "/rab/zab",
                                'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 200, "authorized request gets 200");
            is($res->content, 'Hello foo: /rab/zab',
               "and gets the right content");
        }
    };
}

{
    my $app = builder {
        enable 'Auth::Htpasswd',
            file_root => $data_root->subdir('bar');
        sub {
            [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ "Hello $_[0]->{REMOTE_USER}: $_[0]->{PATH_INFO}" ],
            ]
        };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 401, "no .htpasswd found means deny");
        }
    };
}

{
    my $app = builder {
        enable 'Auth::Htpasswd',
            file_root => $data_root->subdir('foo', 'bar');
        sub {
            [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ "Hello $_[0]->{REMOTE_USER}: $_[0]->{PATH_INFO}" ],
            ]
        };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/", 'Authorization' => 'Basic Zm9vOjEyMzQ=');
            is($res->code, 401, "don't look up above file_root for .htpasswd");
        }
    };
}

done_testing;
