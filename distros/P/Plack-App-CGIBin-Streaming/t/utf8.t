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
use Encode ();

(my $root=__FILE__)=~s![^/]*$!cgi-bin!;

test_psgi
    app=>P->new(
                root=>$root,
                request_params=>[parse_headers=>1],
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        note '/utf8.cgi';
        $res=$cb->(GET '/utf8.cgi');
        like $res->content, qr/^is_utf8: 1/m, 'is a character string';
        ($res=$res->content)=~s/\nis_utf8: .+\n\z//s;
        is length($res), 2, '"ae oe" is 2 bytes (iso)';
        is $res, do {use utf8; 'äö'}, 'is "ae oe"';

        note '/utf8.cgi?u';
        $res=$cb->(GET '/utf8.cgi?u');
        is $res->code, 200, 'status';
        like $res->content, qr/^is_utf8: 1/m, 'is a character string';
        ($res=$res->content)=~s/\nis_utf8: .+\n\z//s;
        is length($res), 4, '"ae oe" is 4 bytes (utf)';
        $res=Encode::decode_utf8($res);
        is $res, do {use utf8; 'äö'}, 'is "ae oe"';
    };

done_testing;
