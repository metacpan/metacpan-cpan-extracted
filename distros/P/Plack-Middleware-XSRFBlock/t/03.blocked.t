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

for my $appname ('psgix.input.non-buffered.blocked') {
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

            my $expected_content=qq{<html>
    <head><title>the form</title></head>
    <body>
        <form action="/post" method="post"><input type="hidden" name="xsrf_token" value="$token" />
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
};
            is ($res->content, $expected_content, 'response content appears sane');

            # check we get our unusual results for our custom blocked app
            $res = teapot_ok (
                $cb->(
                    POST "http://localhost/post",
                    [name => 'Plack', xsrf_token => '123']
                )
            );
            is (
                $res->header('Content-Type'),
                'text/teapot',
                'blocked app returns "text/teapot" as Content-Type',
            );
            is (
                $res->content,
                'That door is firmly closed!',
                'blocked app returns expected content'
            );
        };
    };
}

sub teapot_ok {
    my $res = shift;
    is (
        $res->code,
        HTTP_I_AM_A_TEAPOT,
        sprintf(
            '"POST %s" returns HTTP_FORBIDDEN(%d)',
            $res->request->uri,
            HTTP_FORBIDDEN
        )
    );
    return $res;
}

done_testing;
