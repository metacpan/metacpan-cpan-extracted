use strict;
use warnings;
use Plack::Builder;
use HTTP::Request::Common;

use Test::More 0.88;
use Plack::Test;


{
    my $app = builder {
        enable 'Devel::ForceResponse', rate => 101;
        sub { [ 200, ['Content-Type' => 'text/plain'], ['OK'] ] };
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 500;
            is $res->content_type, 'text/plain';
            is $res->content, 'Internal Server Error';
    };
    test_psgi $app, $cli;
}

done_testing;
