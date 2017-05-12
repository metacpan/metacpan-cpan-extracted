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

# two requests for an app WITHOUT token_per_request should have the same
# token
for my $appname ('psgix.input.non-buffered.token_per_session') {
    subtest $appname => sub {
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar( HTTP::Cookies->new );

        test_psgi ua => $ua, app => $app{$appname}, client => sub {
            my $cb  = shift;
            my ($res, $h_cookie, $jar, $token);
            $jar = $ua->cookie_jar;

            my %token = %{ _two_requests($cb, $ua) };

            is(
                $token{1},
                $token{2},
                'cookie tokens are the same when NOT using token_per_request'
            );
        };
    };
}

# test buffered and non-buffered apps for token_per_request behaviour
for my $appname (
    'psgix.input.non-buffered.token_per_request',
    'psgix.input.buffered.token_per_request',
) {
    subtest $appname => sub {
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar( HTTP::Cookies->new );

        test_psgi ua => $ua, app => $app{$appname}, client => sub {
            my $cb  = shift;
            my ($res, $h_cookie, $jar, $token);

            my %token = %{ _two_requests($cb, $ua) };

            isnt(
                $token{1},
                $token{2},
                'cookie tokens are different using token_per_request'
            );
        };
    };
}

# test buffered and non-buffered apps for token_per_request_sub behaviour
for my $appname (
    'psgix.input.non-buffered.token_per_request_sub',
    'psgix.input.buffered.token_per_request_sub',
) {
    subtest $appname => sub {
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar( HTTP::Cookies->new );

        test_psgi ua => $ua, app => $app{$appname}, client => sub {
            my $cb  = shift;
            my ($res, $h_cookie, $jar, $token);

            my %token = %{ _two_requests($cb, $ua) };

            is(
                $token{1},
                $token{2},
                'cookie tokens are the same for two requests for /form/html using token_per_request_sub'
            );
        };
    };
}

for my $appname (
    'psgix.input.non-buffered.token_per_request_sub',
    'psgix.input.buffered.token_per_request_sub',
) {
    subtest "$appname-post" => sub {
        my $ua = LWP::UserAgent->new;
        $ua->cookie_jar( HTTP::Cookies->new );

        test_psgi ua => $ua, app => $app{$appname}, client => sub {
            my $cb  = shift;
            my ($res, $h_cookie, $jar, $token);

            my %token = %{ _two_requests($cb, $ua, '/form/xhtml') };

            isnt(
                $token{1},
                $token{2},
                'cookie tokens are different for two requests for /form/xhtml using token_per_request_sub'
            );
        };
    };
}


sub _two_requests {
    my ($cb, $ua, $url) = @_;

    $url ||= "/form/html";

    my $jar = $ua->cookie_jar;

    my %token;
    # making two requests should result in different tokens
    for (1..2) {
        my $res = $cb->(GET $url);
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
        $token{$_} = cookie_in_jar_ok($res, $jar);
    }

    return \%token;
}



done_testing;
