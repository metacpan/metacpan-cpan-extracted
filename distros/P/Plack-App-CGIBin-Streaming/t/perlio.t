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

        note '/perlio.cgi';
        $res=$cb->(GET '/perlio.cgi');
        # note explain $res;
        is $res->content, "a bit of content\n", 'content';

        note '/perlio.cgi?buffer';
        $res=$cb->(GET '/perlio.cgi?buffer');
        # note explain $res;
        is $res->content, "a bit of content\n\nbuffered\n", 'buffered content';
    };

done_testing;
