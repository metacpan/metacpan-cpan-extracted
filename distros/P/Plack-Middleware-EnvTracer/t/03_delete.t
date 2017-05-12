use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Capture::Tiny qw/capture_stdout/;
use Test::More;

# DELETE
{
    my $app = builder {
        enable 'EnvTracer';
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

    my $stdout = capture_stdout {
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');

            is $res->code, 200;
            like $res->content, qr{<p>test=1:1</p>};
        };
    };

    note $stdout;
    like $stdout, qr!FETCH:0!;
    like $stdout, qr!STORE:1!;
    like $stdout, qr!EXISTS:2!;
    like $stdout, qr!DELETE:1!;
    like $stdout, qr!DELETE\tTEST_TRACE_ENV!;
}

done_testing;
