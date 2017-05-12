use warnings;
use strict;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Capture::Tiny qw/capture_stdout/;
use Test::More;

# CLEAR
{
    my $app = builder {
        enable 'EnvTracer';
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

    my $stdout = capture_stdout {
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(GET '/');

            is $res->code, 200;
            like $res->content, qr{<p>clear</p>};
        };
    };

    note $stdout;
    like $stdout, qr!FETCH:0!;
    like $stdout, qr!STORE:1!;
    like $stdout, qr!CLEAR:1!;
    like $stdout, qr!PID:\d+\tCLEAR!;
}

done_testing;
