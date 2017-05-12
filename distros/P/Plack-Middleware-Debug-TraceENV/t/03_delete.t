#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

# DELETE
{
    my $app = builder {
        enable 'Debug', panels => [qw/TraceENV/];
        sub {
            $ENV{TEST_TRACE_ENV} = 7;
            my $exists = exists $ENV{TEST_TRACE_ENV};
            delete $ENV{TEST_TRACE_ENV};
            my $deleted = !exists($ENV{TEST_TRACE_ENV});
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>test=$exists:$deleted</p></body></html>"]
            ];
        };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content, qr{<p>test=1:1</p>}, "exists";
        like $res->content, qr{<td>\d+: DELETE</td>}, "label of DELETE";
    };
}

done_testing;
