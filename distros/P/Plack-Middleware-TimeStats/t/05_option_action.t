use strict;
use warnings;
use Test::More;
use Plack::Test;

use Capture::Tiny qw/capture_stderr/;

use Plack::Builder;
use HTTP::Request::Common;

use Plack::Middleware::TimeStats;

{
    my $action = sub {
        my $env = shift;
        return $env->{PATH_INFO}
                    . ($env->{QUERY_STRING} ? "?$env->{QUERY_STRING}" : "");
    };

    my $stderr = capture_stderr {

        my $app = builder {
            enable 'TimeStats', action => $action;
            sub {
                my $env = shift;
                $env->{'psgix.timestats'}->profile('aki');
                [ 200, [], ['OK'] ];
            };
        };
        my $cli = sub {
                my $cb = shift;
                my $res = $cb->(GET '/yui?jejeje=1');
                is $res->code, 200;
                is $res->content, 'OK';
        };
        test_psgi $app, $cli;

    };

    #note $stderr;
    like $stderr, qr!|\s+/yui\?jejeje=1\s+|\s+\d!, 'custom action';
}

done_testing;
