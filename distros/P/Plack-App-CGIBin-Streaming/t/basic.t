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
                request_params=>[parse_headers=>1],
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        note 'NOT FOUND';
        $res=$cb->(GET '/not.found');
        is $res->code, 404, 'status';

        note '/simple.cgi';
        $res=$cb->(GET '/simple.cgi');
        is $res->code, 200, 'status';
        is $res->content, "huhu\n", 'content';
        is $res->header('Content-Length'), 5, 'cl';
        is $res->header('X-My-Header'), 'fritz', 'X- header';
        is $res->header('Content-Type'), 'my/text', 'ct';

        note 'one_piece';
        $res=$cb->(GET '/simple.cgi?one_piece,');
        is $res->code, 404, 'status';
        is $res->content, "huhu\n", 'content';
        is $res->header('Content-Length'), 5, 'cl';
        is $res->header('X-My-Header'), 'fritz', 'X- header';
        is $res->header('Content-Type'), 'my/text', 'ct';

        # max_buffer=8000 (==1600*5)

        note 'max_buffer==8000: exact limit';
        $res=$cb->(GET '/simple.cgi?1600');
        is $res->code, 200, 'status';
        is $res->content, "huhu\n" x 1600, 'content';
        is $res->header('Content-Length'), 1600*5, 'cl';
        is $res->header('X-My-Header'), 'fritz', 'X- header';
        is $res->header('Content-Type'), 'my/text', 'ct';

        note 'max_buffer==8000: exact limit (one piece)';
        $res=$cb->(GET '/simple.cgi?one_piece,1600');
        is $res->code, 404, 'status';
        is $res->content, "huhu\n" x 1600, 'content';
        is $res->header('Content-Length'), 1600*5, 'cl';
        is $res->header('X-My-Header'), 'fritz', 'X- header';
        is $res->header('Content-Type'), 'my/text', 'ct';

        note 'max_buffer==8000: limit exceeded';
        $res=$cb->(GET '/simple.cgi?1601');
        is $res->code, 200, 'status';
        is $res->content, "huhu\n" x 1601, 'content';
        is $res->header('Content-Length'), undef, 'no cl';
    SKIP: {
            skip 'response is not HTTP/1.1', 1
                unless $res->protocol eq 'HTTP/1.1';
            is $res->header('Client-Transfer-Encoding'), 'chunked',
                'te: chunked';
        }
        is $res->header('X-My-Header'), 'fritz', 'X- header';
        is $res->header('Content-Type'), 'my/text', 'ct';

        note 'max_buffer==8000: limit exceeded (one piece)';
        $res=$cb->(GET '/simple.cgi?one_piece,1601');
        is $res->code, 404, 'status';
        is $res->content, "huhu\n" x 1601, 'content';
        is $res->header('Content-Length'), undef, 'no cl';
    SKIP: {
            skip 'response is not HTTP/1.1', 1
                unless $res->protocol eq 'HTTP/1.1';
            is $res->header('Client-Transfer-Encoding'), 'chunked',
                'te: chunked';
        }
        is $res->header('X-My-Header'), 'fritz', 'X- header';
        is $res->header('Content-Type'), 'my/text', 'ct';
    };

done_testing;
