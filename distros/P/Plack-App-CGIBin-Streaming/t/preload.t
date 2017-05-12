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
                preload=>['preload.*i', 'dummy?.cgi'],
                request_params=>[parse_headers=>1],
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        note '/preload.cgi';
        $res=$cb->(GET '/preload.cgi');
        is $res->code, 200, 'status';
        note 'got: '.$res->content;
        like $res->content, qr!/cgi-bin/preload.cgi$!m, 'preload.cgi found';
        like $res->content, qr!/cgi-bin/dummy1.cgi$!m, 'dummy1.cgi found';
        like $res->content, qr!/cgi-bin/dummy2.cgi$!m, 'dummy2.cgi found';
        unlike $res->content, qr!/cgi-bin/simple.cgi$!m, 'simple.cgi not found';
        is $res->header('Content-Type'), 'text/plain', 'ct';
    };

done_testing;
