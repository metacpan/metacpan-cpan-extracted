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
                 parse_headers=>1,
                 content_type=>'text/html; charset=UTF8',
                 on_flush=>sub {
                     my $r=shift;
                     $r->notes->{flushed}++;
                 },
                 on_finalize=>sub {
                     my $r=shift;
                     $r->print_content("\nflushed: ",
                                       ($r->notes->{flushed}+0),
                                      "\n");
                 },
                 suppress_flush=>1,
                 max_buffer=>10,
                ],
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        note '/simple.cgi';
        $res=$cb->(GET '/simple.cgi');
        is $res->code, 200, 'status';
        is $res->content, "huhu\n\nflushed: 0\n", 'content';

        note '/simple.cgi?3';
        $res=$cb->(GET '/simple.cgi?3');
        is $res->code, 200, 'status';
        is $res->content, ("huhu\n" x 3)."\nflushed: 1\n", 'content';

        note '/suppress_flush.cgi';
        $res=$cb->(GET '/suppress_flush.cgi');
        is $res->code, 200, 'status';
        is $res->content, "xxx||xxx\nflushed: 1\n", 'content';

        note '/suppress_flush.cgi?dont_suppress';
        $res=$cb->(GET '/suppress_flush.cgi?dont_suppress');
        is $res->code, 200, 'status';
        is $res->content, "xxx||xxx\nflushed: 7\n", 'content';
    };

done_testing;
