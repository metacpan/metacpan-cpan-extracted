use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Capture::Tiny qw/capture_stdout/;
use Test::More;

# method option
{
    my $app = builder {
        enable 'EnvTracer', methods => [qw/store/];
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

    my $stdout = capture_stdout {
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');

            is $res->code, 200;
            like $res->content, qr{<p>method option</p>}, "method option";
        };
    };

    note $stdout;
    like $stdout, qr!FETCH:-!;
    like $stdout, qr!STORE:2!;
    like $stdout, qr!EXISTS:-!;
}

done_testing;
