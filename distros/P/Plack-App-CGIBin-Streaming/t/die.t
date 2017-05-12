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

        note '/die.cgi';

        $res=$cb->(GET '/die.cgi');
        is $res->code, 500, 'got error 500';
    };

done_testing;
