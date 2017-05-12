#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

# EXISTS
{
    my $app = builder {
        enable 'Debug', panels => [qw/TraceENV/];
        sub {
            $ENV{TEST_TRACE_ENV} = 7;
            my $e = exists $ENV{TEST_TRACE_ENV};
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>ENV:$e</p></body></html>"]
            ];
        };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content, qr{<p>ENV:1</p>}, "exists";
        like $res->content, qr{<td>\d+: EXISTS</td>}, "label of EXISTS";
    };
}

# NO EXISTS
{
    my $app = builder {
        enable 'Debug', panels => [qw/TraceENV/];
        sub {
            my $e = !exists($ENV{__THIS_IS_NO_EXISTS_ENV__});
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>ENV:$e</p></body></html>"]
            ];
        };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content, qr{<p>ENV:1</p>}, "no exists";
        like $res->content, qr{<td>\d+: EXISTS</td>}, "label of EXISTS";
    };
}

done_testing;
