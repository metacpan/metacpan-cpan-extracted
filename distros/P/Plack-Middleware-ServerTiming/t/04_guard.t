use strict;
use warnings;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;
use Plack::ServerTiming;

my $app = builder {
    enable "ServerTiming";
    sub {
        my $env = shift;
        my $t = Plack::ServerTiming->new($env);
        {
            my $g = $t->guard('elapsed', 'sleep 1');
            sleep 1;
        }
        return [200, ['Content-Type'=>'text/html'], ["Hello"]];
    };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    my $server_timing = $res->header('Server-Timing');
    like $server_timing, qr/elapsed;dur=.+;desc="sleep 1"/;
    my ($dur) = $server_timing =~ /elapsed;dur=(.+);/;
    ok $dur >= 500;
};

done_testing;
