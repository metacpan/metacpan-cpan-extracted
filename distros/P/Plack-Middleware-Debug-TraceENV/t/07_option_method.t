#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

# method option
{
    my $app = builder {
        enable 'Debug';
        enable 'Debug::TraceENV', method => [qw/store/];
        sub {
            $ENV{TEST_TRACE_ENV} = 7;
            $ENV{TEST_TRACE_ENV} = 8 if exists $ENV{TEST_TRACE_ENV};
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>method option</p></body></html>"]
            ];
        };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content, qr{<p>method option</p>}, "method option";
        like $res->content, qr{<td>\d+: STORE</td>}, "label of STORE";
        unlike $res->content, qr{<td>\d+: EXISTS</td>}, "no label of EXISTS";
    };
}

done_testing;
