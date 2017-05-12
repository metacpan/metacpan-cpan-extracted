#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

# SCALAR
{
    my $app = builder {
        enable 'Debug', panels => [qw/TraceENV/];
        sub {
            $ENV{TEST_TRACE_ENV} = 7;
            my $r = scalar %ENV;
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>scalar:$r</p></body></html>"]
            ];
        };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content, qr{<p>scalar:\d+(/\d+)?</p>}, "scalar";
        like $res->content, qr{<td>\d+: SCALAR</td>}, "label of SCALAR";
    };
}

done_testing;
