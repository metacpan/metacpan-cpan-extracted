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
use Encode qw/encode/;
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

        my $string="äö"x2;
        my $expected=unpack( 'H*', (encode('iso-8859-1', $string).
                                    encode('utf-8', $string).
                                    encode('iso-8859-1', $string).
                                    encode('utf-8', $string).
                                    encode('iso-8859-1', $string)) );

        note '/io-binmode.cgi?:bytes';

        $res=$cb->(GET '/io-binmode.cgi?:bytes');

        is unpack( 'H*', $res->content), $expected, 'bytes and utf8 mixed';

        TODO: {
            $TODO='Not yet figured out how to do it';

            note '/io-binmode.cgi?:raw';

            $res=$cb->(GET '/io-binmode.cgi?:raw');

            is unpack( 'H*', $res->content), $expected, 'bytes and utf8 mixed';

            note '/io-binmode.cgi';

            $res=$cb->(GET '/io-binmode.cgi');

            is unpack( 'H*', $res->content), $expected, 'bytes and utf8 mixed';
        }
    };

done_testing;
