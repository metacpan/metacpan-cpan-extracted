use warnings;
use strict;

use Test::More tests => 2;
use Test::Mock::Guard qw(mock_guard);
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;

my $app = builder {
    enable 'Session::Cookie', secret => 'secret';
    enable 'HatenaOAuth', (
        consumer_key    => 'xxxx',
        consumer_secret => 'yyyy',
        login_path      => '/login',
        ua              => LWP::UserAgent->new,
    );
    sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;

        my $auth_path = '/login?oauth_token=xxx&oauth_verifier=zzz';
        my $login_path = '/login?location=/callback-path';

        my $g = mock_guard 'LWP::UserAgent', {
            request => sub {
                return HTTP::Response->new(400, '', [], 'Bad request');
            },
        };

        subtest 'Request token' => sub {
            my $req = HTTP::Request->new(GET => "http://localhost$login_path");
            ok my $res = $cb->($req);
            is $g->call_count('LWP::UserAgent', 'request'), 1;
            is $res->code, 500;
            like $res->decoded_content, qr!Could not get an OAuth request token!;
        };

        do {
            my $access_token = mock_guard 'LWP::UserAgent', {
                request => sub { return HTTP::Response->new(
                    200, '', [],
                    'oauth_token=xxx&oauth_token_secret=yyy&oauth_callback_confirmed=true'
                ); },
            };
            my $req = HTTP::Request->new(GET => "http://localhost$login_path");
            $cb->($req);
        };

        subtest 'Authorize' => sub {
            my $req = HTTP::Request->new(GET => "http://localhost$auth_path");
            ok my $res = $cb->($req);
            is $g->call_count('LWP::UserAgent', 'request'), 3;
            is $res->code, 500;
            like $res->decoded_content, qr!Could not get an OAuth access token!;
        };
    };
