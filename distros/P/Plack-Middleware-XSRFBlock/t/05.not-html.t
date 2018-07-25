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

            $res = $cb->(GET "/form/text");
            is (
                $res->code,
                HTTP_OK,
                sprintf(
                    'GET %s returns HTTP_OK(%d)',
                    $res->request->uri,
                    HTTP_OK
                )
            );
            $h_cookie = $res->header('Set-Cookie') || '';
            is($h_cookie, '', 'Not trying to Set-Cookie on non-html');
            # we should have no (previous) cookies floating around
            $jar->extract_cookies($res);
            unlike(
                $jar->as_string,
                qr{PSGI-XSRF-Token},
                'no sign of PSGI-XSRF-Token in cookie jar',
            );

            unlike(
                $res->content,
                qr{xsrf_token},
                'no token should have been added to the contents',
            );
        };
    };
}

done_testing;

