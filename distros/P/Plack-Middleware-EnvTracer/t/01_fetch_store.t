use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Capture::Tiny qw/capture_stdout/;
use Test::More;

# STORE & FETCH
{
    my $app = builder {
        enable 'EnvTracer';
        sub {
            $ENV{TEST_TRACE_ENV} = 7;

            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>ENV:$ENV{TEST_TRACE_ENV}</p></body></html>"]
            ];
        };
    };

    my $stdout = capture_stdout {
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');

            is $res->code, 200;
            like $res->content, qr{<p>ENV:7</p>};
        };
    };

    note $stdout;
    like $stdout, qr!FETCH:1!;
    like $stdout, qr!STORE:1!;
    like $stdout, qr!EXISTS:0!;
    like $stdout, qr!STORE\tTEST_TRACE_ENV=7!;
    like $stdout, qr!FETCH\tTEST_TRACE_ENV!;
}

done_testing;
