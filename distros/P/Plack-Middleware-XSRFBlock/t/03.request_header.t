#!perl
use Test::More;
use strict;
use warnings;

use HTTP::Cookies;
use HTTP::Request::Common;
use HTTP::Status ':constants';
use LWP::UserAgent;
use Plack::Builder;
use Plack::Test;
use Plack::Session::State::Cookie;

use FindBin::libs;
use Test::XSRFBlock::App;
use Test::XSRFBlock::Util ':all';

my %app = %{ Test::XSRFBlock::App->setup_test_apps };

for my $appname ('psgix.input.non-buffered.request_header') {
    subtest $appname => sub {
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar( HTTP::Cookies->new );

        test_psgi ua => $ua, app => $app{$appname}, client => sub {
            my $cb  = shift;
            my ($res, $h_cookie, $jar, $token);
            $jar = $ua->cookie_jar;

            # make a standard get request; we shouldn't trigger any xSRF
            # rejections but we *should* see the header trying to set the new
            # cookie
            $res = $cb->(GET "/form/html");
            is (
                $res->code,
                HTTP_OK,
                sprintf(
                    'GET %s returns HTTP_OK(%d)',
                    $res->request->uri,
                    HTTP_OK
                )
            );
            set_cookie_ok($res);
            $token = cookie_in_jar_ok($res, $jar);

            # we now have a value in the cookie that we can use as out token
            # for any requests/header tests

            # let's verify that we've got the value we expect in the meta-tag
            my $expected_content=qq{<html>
    <head><meta name="my_xsrf_meta_tag" content="$token"/><title>the form</title></head>
    <body>
        <form action="/post" method="post"><input type="hidden" name="xsrf_token" value="$token" />
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
};
            is ($res->content, $expected_content, 'response content appears sane');

            $res = $cb->(GET "/form/html");
            is (
                $res->code,
                HTTP_OK,
                sprintf(
                    'GET %s returns HTTP_OK(%d)',
                    $res->request->uri,
                    HTTP_OK
                )
            );

            # we should NOT see the X- header in the response from the GET
            ok(
                not(defined($res->header('X-XSRF-Token'))),
                'X-XSRF-Token response header not present (as expected)'
            )
                or _debug_fail($res);

            # because we're running on an 'allows X- header' instance our
            # missing token value message should be slightly different
            $res = forbidden_ok(
                $cb->(POST "http://localhost/post", [name => 'Plack'])
            );
            is (
                $res->content,
                'XSRF detected [xsrf token missing]',
                'correct error in response body when token missing from POST'
            );

            # now send the same post with the X- header in the request
            $res = $cb->(
                POST "http://localhost/post",
                [name => 'Plack'],
                'X-XSRF-Token' => $token
            );
            is (
                $res->code,
                HTTP_OK,
                sprintf(
                    '"POST %s" returns HTTP_OK(%d)',
                    $res->request->uri,
                    HTTP_OK
                )
            )
                or _debug_fail($res);
        };
    };
}

# make sure we DO NOT get headers if we didn't ask for them
for my $appname ('psgix.input.non-buffered', 'psgix.input.buffered') {
    subtest $appname => sub {
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar( HTTP::Cookies->new );

        test_psgi ua => $ua, app => $app{$appname}, client => sub {
            my $cb  = shift;
            my ($res, $h_cookie, $jar, $token);
            $jar = $ua->cookie_jar;

            # ensure we DO NOT have the X- header
            $res = $cb->(GET "/form/html");
            is (
                $res->code,
                HTTP_OK,
                sprintf(
                    'GET %s returns HTTP_OK(%d)',
                    $res->request->uri,
                    HTTP_OK
                )
            );
            ok(
                not(defined($res->header('X-XSRF-Token'))),
                'X-XSRF-Token response header not present (as expected)'
            )
                or _debug_fail($res);
        };
    };
}

sub _debug_fail {
    my $res = shift;
    use Data::Printer alias=>'splat'; diag $res->content; diag $res->code; diag splat($res->headers);
}

done_testing;
