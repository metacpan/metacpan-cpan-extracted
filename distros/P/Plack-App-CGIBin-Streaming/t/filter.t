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
                 filter_before=>sub {
                     my ($r, $list)=@_;
                     for (@$list) {
                         if (s/<!-- FlushHead -->//) {
                             $r->filter_after=sub {
                                 $_[0]->flush;
                                 $_[0]->filter_after=sub{};
                             };
                             $r->filter_before=sub{};
                         }
                     }
                 },
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
                 on_status_output=>sub {
                     my $r=shift;

                     if ($r->status==200 and
                         $r->content_type=~m!^text/html!) {
                         $r->print_header('on-status-out', 'is_html');
                     } else {
                         $r->print_header('on-status-out', 'no_html/error');
                     }
                 },
                ],
               )->to_app,
    client=>sub {
        my $cb=shift;
        my $res;

        note '/using-R.cgi';
        $res=$cb->(GET '/using-R.cgi');
        is $res->code, 200, 'default status';
        is $res->header('on-status-out'), 'is_html', 'on_status_out';
        is $res->content, "x\nflushed: 0\n", 'content';

        note '/using-R.cgi?status,404';
        $res=$cb->(GET '/using-R.cgi?status,404');
        is $res->code, 404, 'status';
        is $res->header('on-status-out'), 'no_html/error', 'on_status_out';

        note '/using-R.cgi?flush_after,102,cl,304';
        $res=$cb->(GET '/using-R.cgi?flush_after,102,cl,304');

        # The flush token is inserted after the actual output when it's size
        # exceeded 102. So, after the first chunk of 100 bytes there is no
        # flush. Only after the 2nd chunk is a flush token inserted. The filter
        # finds it, removes "<!-- FlushHead -->" but leaves "\nflushed\n".
        # Then it removes itself and installs an "after" filter to perform the
        # actual flush operation. The "after" filter also removes itself.
        # All following flush tokens are simply put through.
        # Again, the flush token is not printed after the 1st chunk of
        # 100 bytes, only after the last one.
        is $res->content, (('x' x 200).
                           "\nflushed\n".
                           ('x' x 104).
                           "\nflushed\n<!-- FlushHead -->".
                           "\nflushed: 1\n"), 'output filtered';

        note '/using-R.cgi?flush_after,102,cl,304,pc,1';
        $res=$cb->(GET '/using-R.cgi?flush_after,102,cl,304,pc,1');
        # see above for an explanation
        is $res->content, (('x' x 200).
                           "\nflushed\n".
                           ('x' x 104).
                           "<!-- FlushHead -->\nflushed\n".
                           "\nflushed: 1\n"), 'output filtered';
    };

done_testing;
