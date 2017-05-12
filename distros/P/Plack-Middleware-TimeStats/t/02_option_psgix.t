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
            enable 'TimeStats', psgix => 'ama';
            sub {
                my $env = shift;
                $env->{'psgix.ama'}->profile('aki');
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
    like $stderr, qr!|\s+- aki\s+|!, 'action';
}

done_testing;
