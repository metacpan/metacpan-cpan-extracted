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

# normal input
my %app = %{ Test::XSRFBlock::App->setup_test_apps };

for my $appname ('psgix.input.non-buffered', 'psgix.input.buffered') {
    subtest $appname => sub {
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar( HTTP::Cookies->new );

        test_psgi ua => $ua, app => $app{$appname}, client => sub {
            my $cb  = shift;
            my ($res, $h_cookie, $jar, $token);
            $jar = $ua->cookie_jar;

            # make a post with no cookie & no token
            # we should be forbidden and have no attempt made to set the tokn
            # cookie
            $res = forbidden_ok(
                $cb->(POST "http://localhost/post", [name => 'Plack'])
            );
            $h_cookie = $res->header('Set-Cookie') || '';
            is($h_cookie, '', 'Not trying to Set-Cookie after failed POST');
            # we should have no (previous) cookies floating around
            $jar->extract_cookies($res);
            unlike(
                $jar->as_string,
                qr{PSGI-XSRF-Token},
                'no sign of PSGI-XSRF-Token in cookie jar',
            );

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

            # make a POST with no token; we should NOT be trying to set the
            # cookie; we *should* be able to find the relevant cookie and get
            # a value from it
            $res = forbidden_ok(
                $cb->(POST "http://localhost/post", [name => 'Plack'])
            );
            is (
                $res->content,
                'XSRF detected [form field missing]',
                'correct error in response body when token missing from POST'
            );
            $h_cookie = $res->header('Set-Cookie') || '';
            is($h_cookie, '', 'No longer trying to Set-Cookie');
            # the token is still in the jar
            my $token2 = cookie_in_jar_ok(
                $res, $jar,
                'cookie has a defined value when retrieved after failed POST'
            );
            is(
                $token2,
                $token,
                sprintf(
                    'cookie has the same value as previous request [%s]',
                    $token2
                )
            );

            # posting a junk/invalid token should be forbidden
            $res = forbidden_ok (
                $cb->(
                    POST "http://localhost/post",
                    [name => 'Plack', xsrf_token => '123']
                )
            );
            is (
                $res->content,
                'XSRF detected [invalid token]',
                'correct error in response body when invalid token in POST'
            );

            # now we have a value for the token that we can submit with forms

            # make a POST with no token; we should NOT be trying to set the
            # cookie; we *should* be able to find the relevant cookie and get
            # a value from it
            $res = $cb->(
                POST "http://localhost/post",
                [name => 'Plack', xsrf_token => $token]
            );
            is (
                $res->code,
                HTTP_OK,
                sprintf(
                    'POSTing to %s with token returns HTTP_OK(%d)',
                    $res->request->uri,
                    HTTP_OK
                )
            );
        };
    };
}

done_testing;
