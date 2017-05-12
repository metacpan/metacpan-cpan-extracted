use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Capture::Tiny qw/capture_stdout/;
use Test::More;

# FIRSTKEY & NEXTKEY
{
    my $app = builder {
        enable 'EnvTracer';
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

    my $stdout = capture_stdout {
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');

            is $res->code, 200;
            like $res->content, qr{<p>TEST_TRACE_ENV:1:1</p>};
        };
    };

    note $stdout;
    like $stdout, qr!FETCH:2!;
    like $stdout, qr!STORE:2!;
    like $stdout, qr!FIRSTKEY:1!;
    like $stdout, qr!NEXTKEY:\d+!;
    like $stdout, qr!STORE\tTEST_TRACE_ENV=7!;
    like $stdout, qr!STORE\tTEST_TRACE_ENV2=8!;
    like $stdout, qr!FETCH\tTEST_TRACE_ENV2!;
    like $stdout, qr!FETCH\tTEST_TRACE_ENV!;
}

done_testing;
