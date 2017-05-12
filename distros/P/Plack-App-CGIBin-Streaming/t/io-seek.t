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
                request_params=>
                [
                 content_type=>'text/html; charset=UTF8',
                 parse_headers=>1,
                ],
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        note '/io-seek.cgi small';

        my $content=join '', map {pack('A19', $_)."\n"} 1..100;
        $res=$cb->(POST '/io-seek.cgi?10,5,3,82', Content=>$content);
        is $res->code, 200, 'status';

    SKIP: {
            skip 'input is not buffered', 1 if $res->content eq "n/a\n";
            is $res->content, join( '',
                                    map {pack('A19', $_)."\n"}
                                    10, 5, 3, 82), 'content';
        }

        note '/io-seek.cgi large';

        my $content=join '', map {pack('A19', $_)."\n"} 1..100000;
        $res=$cb->(POST '/io-seek.cgi?1000,500,300,8200', Content=>$content);
        is $res->code, 200, 'status';
        note $res->request->header('content-length');

    SKIP: {
            skip 'input is not buffered', 1 if $res->content eq "n/a\n";
            is $res->content, join( '',
                                    map {pack('A19', $_)."\n"}
                                    1000, 500, 300, 8200), 'content';
        }
    };

done_testing;
