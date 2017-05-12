use strict;
use warnings;
use Test::More;
use Plack::Test;

use Capture::Tiny qw/capture_stdout capture_merged/;

use Plack::Builder;
use HTTP::Request::Common;

use Plack::Middleware::TimeStats;

{
    my $merged = capture_merged {

        my $app = builder {
            enable 'TimeStats', callback => sub {};
            sub {
                my $env = shift;
                $env->{'psgix.timestats'}->profile('aki');
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

    #note $merged;
    is $merged, '', 'blank output';
}

{
    my $callback = sub {
        my ($stats, $env, $res) = @_;
        print STDOUT $env->{PATH_INFO}. "\n";
        print STDOUT scalar($stats->report);
        print STDOUT $res->[0]. "\n";
    };

    my $stdout = capture_stdout {

        my $app = builder {
            enable 'TimeStats', callback => $callback;
            sub {
                my $env = shift;
                $env->{'psgix.timestats'}->profile('aki');
                [ 200, [], ['OK'] ];
            };
        };
        my $cli = sub {
                my $cb = shift;
                my $res = $cb->(GET '/jejeje');
                is $res->code, 200;
                is $res->content, 'OK';
        };
        test_psgi $app, $cli;

    };

    #note $stdout;
    like $stdout, qr!^/jejeje!, 'PATH_INFO';
    like $stdout, qr!|\s+Action\s+|\s+Time\s+|\s+%\s+|!, 'table';
    like $stdout, qr!|\s+-\saki\s+|\s+\d+\.\d+s\s+|\s+\d+\.\d+\s+|!, 'table line';
    like $stdout, qr!200$!, 'response code in output';
}


done_testing;
