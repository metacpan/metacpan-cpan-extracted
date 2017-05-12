#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;

# FIRSTKEY & NEXTKEY
{
    my $app = builder {
        enable 'Debug', panels => [qw/TraceENV/];
        sub {
            $ENV{TEST_TRACE_ENV}  = 7;
            $ENV{TEST_TRACE_ENV2} = 8;
            my $flag  = 0;
            my $flag2 = 0;
            for my $k (keys %ENV) {
                $flag  = 1 if $k eq 'TEST_TRACE_ENV'  && $ENV{$k} == 7;
                $flag2 = 1 if $k eq 'TEST_TRACE_ENV2' && $ENV{$k} == 8;
            }
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>TEST_TRACE_ENV:$flag:$flag2</p></body></html>"]
            ];
        };
    };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'response status 200';

        like $res->content, qr{<p>TEST_TRACE_ENV:1:1</p>}, "FIRSTKEY";
        like $res->content, qr{<td>\d+: FIRSTKEY</td>}, "label of FIRSTKEY";
        like $res->content, qr{<td>\d+: NEXTKEY</td>}, "label of NEXTKEY";
    };
}

done_testing;
