use warnings;
use strict;

use Test::More tests => 3;
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
    sub {
        my $env = $_[0];
        my $session = Plack::Session->new($env);
        my $user_info = $session->get('hatenaoauth_user_info');
        my $user_name = $user_info->{url_name};
        return [ 404, [ 'Content-Type' => 'text/plain' ], [ 'Not found' ] ]
            unless $user_name;
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $user_name ] ];
    };
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;

        my $auth_path = '/login?oauth_token=xxx&oauth_verifier=zzz';
        my $login_path = '/login?location=/callback-path';
        my $response = +{
            'https://www.hatena.com/oauth/initiate' => 'oauth_token=xxx&oauth_token_secret=yyy&oauth_callback_confirmed=true',
            'https://www.hatena.com/oauth/token' => 'oauth_token=xxx&oauth_token_secret=yyy',
            'http://n.hatena.com/applications/my.json' => '{"url_name":"tarao"}',
        };
        my $g = mock_guard 'LWP::UserAgent', {
            request => sub {
                my $req = $_[1];
                is $req->method, 'POST';
                my $res = $response->{$req->uri.q()};
                fail unless $res;
                return HTTP::Response->new(200, '', [], $res);
            },
        };
        my $cookie;

        subtest 'Request token' => sub {
            my $req = HTTP::Request->new(GET => "http://localhost$login_path");
            ok my $res = $cb->($req);
            is $g->call_count('LWP::UserAgent', 'request'), 1;
            is $res->code, 302;
            $cookie = $res->header('Set-Cookie');
            my $redirect = $res->header('Location');
            is $redirect, 'https://www.hatena.ne.jp/oauth/authorize?oauth_token=xxx';
        };

        subtest 'Authorize' => sub {
            my $req = HTTP::Request->new(GET => "http://localhost$auth_path");
            $req->header(Cookie => $cookie);
            ok my $res = $cb->($req);
            $cookie = $res->header('Set-Cookie');
            is $g->call_count('LWP::UserAgent', 'request'), 3;
            is $res->code, 302;
            is $res->header('Location'), '/callback-path';
        };

        subtest 'Login' => sub {
            my $req = HTTP::Request->new(GET => "http://localhost/");
            $req->header(Cookie => $cookie);
            ok my $res = $cb->($req);
            is $res->decoded_content, 'tarao';
        };
    };
