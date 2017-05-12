#!perl
use strict;
use Test::More;
use HTTP::Request::Common;
use constant P=>'Plack::App::CGIBin::Streaming';

BEGIN {
    unless (defined $ENV{PLACK_TEST_IMPL}) {
        unshift @INC, 't';
        @ENV{qw/PLACK_TEST_IMPL PLACK_SERVER/}=qw/Server TestServer/;
    }
}
use Plack::Test;
use Plack::App::CGIBin::Streaming;

(my $root=__FILE__)=~s![^/]*$!cgi-bin!;

test_psgi
    app=>P->new(
                root=>$root,
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        note '/using-R.cgi';
        $res=$cb->(GET '/using-R.cgi');
        is $res->code, 200, 'default status';
        is $res->content, "x", 'content';
        is $res->header('Content-Length'), 1, 'cl';
        is $res->header('Content-Type'), 'text/plain', 'default ct';

        note '/using-R.cgi?pc,1,status,404,cl,8001,ct,xxx,H,a:b,H,a:c';
        $res=$cb->(GET '/using-R.cgi?pc,1,status,404,cl,8001,ct,x,H,a:b,H,a:c');
        is $res->code, 404, 'status';
        is $res->content, "x" x 8001, 'content';
        is $res->header('Content-Length'), undef, 'no cl';
        is $res->header('Content-Type'), 'x', 'ct';
        is $res->header('a'), 'b, c', 'print_header';
        is $res->header('pc'), '1', 'print_content';
    };

done_testing;
