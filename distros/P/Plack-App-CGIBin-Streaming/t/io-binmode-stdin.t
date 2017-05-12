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
use Encode qw/encode_utf8 decode_utf8 encode/;
use utf8;

(my $root=__FILE__)=~s![^/]*$!cgi-bin!;

test_psgi
    app=>P->new(
                root=>$root,
                request_params=>
                [
                 content_type=>'text/html; charset=UTF8',
                 parse_headers=>1,
                ],
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        my $content=encode_utf8("äö"x2);
        my $expected_bytes=unpack( 'H*', $content);
        my $expected_utf8=unpack( 'H*', encode('iso-8859-1',
                                               decode_utf8($content)));

        note 'content: '.$expected_bytes;
        note '/io-binmode-stdin.cgi';

        $res=$cb->(POST '/io-binmode-stdin.cgi', Content=>$content);
        is $res->code, 200, 'status';

        is unpack( 'H*', $res->content), $expected_bytes, 'no encoding';

        note '/io-binmode-stdin.cgi?:utf8';

        $res=$cb->(POST '/io-binmode-stdin.cgi?:utf8', Content=>$content);
        is $res->code, 200, 'status';

        is unpack( 'H*', $res->content), $expected_utf8, ':utf8';

        note '/io-binmode-stdin.cgi?:encoding(utf8)';

        $res=$cb->(POST '/io-binmode-stdin.cgi?:encoding(utf8)',
                   Content=>$content);
        is $res->code, 200, 'status';

        is unpack( 'H*', $res->content), $expected_utf8, ':encoding(utf8)';
    };

done_testing;
