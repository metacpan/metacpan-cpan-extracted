#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

# CLEAR
{
    my $app = builder {
        enable 'Debug', panels => [qw/TraceENV/];
        sub {
            $ENV{TEST_TRACE_ENV} = 7;
            %ENV = ();
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>clear</p></body></html>"]
            ];
        };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content, qr{<p>clear</p>}, "clear";
        like $res->content, qr{<td>\d+: CLEAR</td>}, "label of CLEAR";
    };
}

done_testing;
