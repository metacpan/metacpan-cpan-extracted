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

        note '/io.cgi';
        $res=$cb->(POST '/io.cgi', [name=>'binary.com', country=>'Malaysia']);
        is $res->code, 200, 'status';
        is $res->content, <<'EOF', 'content';
blah blah
name=binary.com&country=Malaysia

length: 32
method: POST
st1: 
st2: 
EOF

        note '/io.cgi (large post)';
        my $x='x' x 10000;
        $res=$cb->(POST '/io.cgi', [x=>$x]);
        is $res->code, 200, 'status';
        is $res->content, <<"EOF", 'content';
blah blah
x=$x

length: 10002
method: POST
st1: 
st2: 1
EOF

        note '/io.cgi (larger post)';
        my $x='x' x 8_000_000;
        $res=$cb->(POST '/io.cgi', [x=>$x]);
        is $res->code, 200, 'status';
        is $res->content, <<"EOF", 'content';
blah blah
x=$x

length: 8000002
method: POST
st1: 
st2: 1
EOF
    };

done_testing;
