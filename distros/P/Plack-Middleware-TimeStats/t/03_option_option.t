use strict;
use warnings;
use Test::More;
use Plack::Test;

use Capture::Tiny qw/capture_stderr/;

use Plack::Builder;
use HTTP::Request::Common;

use Plack::Middleware::TimeStats;

{
    my $option = +{
        percentage_decimal_precision => 3,
        color_map => +{
            '0.01' => 'green3',
            '0.05' => 'green1',
            '0.1'  => 'magenta3',
            '0.5'  => 'magenta1',
        },
    };

    my $stderr = capture_stderr {

        my $app = builder {
            enable 'TimeStats', option => $option;
            sub {
                my $env = shift;
                $env->{'psgix.timestats'}->profile('aki');
                sleep 1;
                $env->{'psgix.timestats'}->profile('yui');
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
    like $stderr, qr!|\s+- yui\s+|!, 'action';

    like $stderr, qr!|[^|]+|[^|]+|[^\d]+\d+\.\d\d\d[^\d]+|!, 'decimal';
}


done_testing;
