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

subtest 'set cookie_options' => sub {
    my $ua = LWP::UserAgent->new;
    $ua->cookie_jar( HTTP::Cookies->new );

    my $appname = 'psgix.input.non-buffered.cookie_options';
    test_psgi ua => $ua,app => $app{$appname}, client => sub {
        my $cb  = shift;
        my ($res, $h_cookie, $jar, $token);
        $jar = $ua->cookie_jar;

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
        my $set_cookie = $res->header('Set-Cookie');
        like $set_cookie => qr/secure/i, 'Got secure in cookie';
        like $set_cookie => qr/httponly/i, 'Got HttpOnly in cookie';

    };
};

done_testing;
