use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

use Plack::Middleware::OIDC;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestOIDC::Logger;

my $oidc_config = {
  authentication_error_path => '/error',
  provider                  => {
    my_provider => {
      id                   => 'my-app-id',
      secret               => 'my-app-secret',
      authorize_url        => 'https://provider.example.com/authorize',
      token_url            => 'https://provider.example.com/token',
      issuer               => 'https://provider.example.com',
      signin_redirect_path => '/oidc/login/callback',
      logout_redirect_path => '/oidc/logout/callback',
    },
  },
};

my $inner_app = sub {
  my $env = shift;

  my $flash = $env->{'psgix.session'}{oidc_flash};

  return [200, ['Content-Type' => 'text/plain'],
          [ $flash ? 'flash: ' . $flash->{error_message} : 'no flash' ]];
};

my $app = builder {
  enable 'Session';

  enable sub {
    my $app = shift;
    TestOIDC::Logger->middleware($app);
  };

  enable 'OIDC', config => $oidc_config;
  $inner_app;
};

test_psgi $app, sub {
  my $cb = shift;

  my ($cookie);

  subtest '1) login callback with an unknown state -> redirect to the error path' => sub {
    my $res1 = $cb->(GET '/oidc/login/callback?code=some-code&state=unknown-state');
    is($res1->code, 302, 'authentication error redirects');
    ($cookie) = ($res1->header('Set-Cookie') // '') =~ /^([^;]+)/;
    ok($cookie, 'a session cookie has been set');
  };

  subtest '2) the request following the redirect can read the message' => sub {
    my $res2 = $cb->(GET '/error', Cookie => $cookie);
    like($res2->content, qr/^flash: .*unknown-state/,
         'message available during the request following the redirect');
  };

  subtest '3) another request can not read the message' => sub {
    my $res3 = $cb->(GET '/error', Cookie => $cookie);
    is($res3->content, 'no flash', 'message removed after the request following the redirect');

    my $res4 = $cb->(GET '/anything', Cookie => $cookie);
    is($res4->content, 'no flash', 'message still absent afterwards');
  };

  subtest '4) a new error sets a new message, independently of the previous one' => sub {
    $cb->(GET '/oidc/login/callback?code=some-code&state=another-state', Cookie => $cookie);
    my $res5 = $cb->(GET '/error', Cookie => $cookie);
    like($res5->content, qr/^flash: .*another-state/, 'a new error produces a new message');
  };

  subtest '5) a session without any error is left untouched' => sub {
    my $res6 = $cb->(GET '/');
    is($res6->content, 'no flash', 'no message without error');
  };
};

done_testing();
