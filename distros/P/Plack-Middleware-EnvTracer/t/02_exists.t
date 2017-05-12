use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Capture::Tiny qw/capture_stdout/;
use Test::More;

# EXISTS
{
    my $app = builder {
        enable 'EnvTracer';
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

    my $stdout = capture_stdout {
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');

            is $res->code, 200;

            like $res->content, qr{<p>ENV:1</p>};
        };
    };

    note $stdout;
    like $stdout, qr!FETCH:0!;
    like $stdout, qr!STORE:1!;
    like $stdout, qr!EXISTS:1!;
    like $stdout, qr!STORE\tTEST_TRACE_ENV=7!;
    like $stdout, qr!EXISTS\tTEST_TRACE_ENV!;
}

# NO EXISTS
{
    my $app = builder {
        enable 'EnvTracer';
        sub {
            my $e = !exists($ENV{__THIS_IS_NO_EXISTS_ENV__});
            return [
                200,
                ['Content-Type' => 'text/html'],
                ["<html><body><p>ENV:$e</p></body></html>"]
            ];
        };
    };

    my $stdout = capture_stdout {
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');

            is $res->code, 200;

            like $res->content, qr{<p>ENV:1</p>};
        };
    };

    note $stdout;
    like $stdout, qr!FETCH:0!;
    like $stdout, qr!STORE:0!;
    like $stdout, qr!EXISTS:1!;
    like $stdout, qr!EXISTS\t__THIS_IS_NO_EXISTS_ENV__!;
}

done_testing;
