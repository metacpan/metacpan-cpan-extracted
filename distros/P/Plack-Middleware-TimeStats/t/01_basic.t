use strict;
use warnings;
use Test::More;
use Plack::Test;

use Capture::Tiny qw/capture_stderr/;

use Plack::Builder;
use HTTP::Request::Common;

use Plack::Middleware::TimeStats;

{
    my $stderr = capture_stderr {

        my $app = builder {
            enable 'TimeStats';
            sub {
                my $env = shift;
                $env->{'psgix.timestats'}->profile('foo');
                [ 200, [], ['OK'] ];
            };
        };
        my $cli = sub {
                my $cb = shift;
                my $res = $cb->(GET '/');
                is $res->code, 200;
                is $res->content, 'OK';
        };
        test_psgi $app, $cli;

    };

    #note $stderr;
    like $stderr, qr!|\s+Action\s+|\s+Time\s+|\s+%\s+|!, 'header';
    like $stderr, qr!|\s+/\s+|!, '/';
    like $stderr, qr!|\s+- foo\s+|!, 'action';
}

{
    my $stderr = capture_stderr {

        my $app = builder {
            enable 'TimeStats';
            sub {
                my $env = shift;
                $env->{'psgix.timestats'}->profile('bar');
                [ 200, [], ['OK'] ];
            };
        };
        my $cli = sub {
                my $cb = shift;
                my $res = $cb->(GET '/baz?hoge=1');
                is $res->code, 200;
                is $res->content, 'OK';
        };
        test_psgi $app, $cli;

    };

    #note $stderr;
    like $stderr, qr!|\s+Action\s+|\s+Time\s+|\s+%\s+|!, 'header';
    like $stderr, qr!|\s+/baz\s+|!, '/';
    like $stderr, qr!|\s+- bar\s+|!, 'action';
}

done_testing;
