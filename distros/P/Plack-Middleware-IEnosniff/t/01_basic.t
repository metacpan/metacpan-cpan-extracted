use strict;
use Plack::Builder;
use HTTP::Request::Common;
use LWP::UserAgent;

use Test::More 0.88;
use Plack::Test;

my $res = sub { [ 200, ['Content-Type' => 'text/plain'], ['OK'] ] };

{
    my $app = builder {
        enable 'IEnosniff';
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/plain';
            is $res->content, 'OK';
            is $res->header('X-Content-Type-Options'), 'nosniff';
    };
    test_psgi $app, $cli;
}

{
    my $app = builder {
        enable 'IEnosniff', only_ie => 1;
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => '/');
            $req->header(
                'User-Agent' => 'Mozilla/4.0', # not include 'MSIE 8'
            );
            my $res = $cb->($req);
            is $res->code, 200;
            is $res->header('X-Content-Type-Options'), undef;
    };
    test_psgi $app, $cli;
}


{
    my $app = builder {
        enable 'IEnosniff', only_ie => 1;
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => '/');
            $req->header(
                'User-Agent' => '',
            );
            my $res = $cb->($req);
            is $res->code, 200;
            is $res->header('X-Content-Type-Options'), undef;
    };
    test_psgi $app, $cli;
}

{
    my $app = builder {
        enable 'IEnosniff', only_ie => 1;
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => '/');
            $req->header(
                'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1)'
            );
            my $res = $cb->($req);
            is $res->code, 200;
            is $res->header('X-Content-Type-Options'), 'nosniff';
    };
    test_psgi $app, $cli;
}

done_testing;
