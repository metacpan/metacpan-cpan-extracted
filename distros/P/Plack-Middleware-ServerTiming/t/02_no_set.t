use strict;
use warnings;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;

my $app = builder {
    enable "ServerTiming";
    sub {
        return [200, ['Content-Type'=>'text/html'], ["Hello"]];
    };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    is $res->header('Server-Timing'), undef;
};

done_testing;
