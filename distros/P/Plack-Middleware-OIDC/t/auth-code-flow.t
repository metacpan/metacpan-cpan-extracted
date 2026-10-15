use strict;
use warnings;
use utf8;
use Test::More;
use Test::MockModule;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use URI;
use URI::QueryParam;

use OIDC::Client::TokenResponse;
use Plack::Middleware::OIDC;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestOIDC::Logger;

# ----------------------------------------------------------------------
# Mock the network calls made by OIDC::Client (token endpoint, JWT decoding)
# ----------------------------------------------------------------------

my $mock_client = Test::MockModule->new('OIDC::Client');
$mock_client->redefine('get_token' => sub {
  return OIDC::Client::TokenResponse->new(
    access_token => 'access-token-value',
    id_token     => 'id-token-value',
    token_type   => 'Bearer',
    expires_in   => 3600,
  );
});
$mock_client->redefine('verify_jwt_token' => sub {
  my ($self, %params) = @_;
  return (
    { alg => 'RS256' },
    {
      sub   => 'jdoe',
      exp   => time + 3600,
      email => 'jdoe@example.com',
      $params{expected_nonce} ? (nonce => $params{expected_nonce}) : (),
    },
  );
});

# ----------------------------------------------------------------------
# Application under test
# ----------------------------------------------------------------------

my $oidc_config = {
  default_provider => 'my_provider',
  provider         => {
    my_provider => {
      id                    => 'my-app-id',
      secret                => 'my-app-secret',
      authorize_url         => 'https://provider.example.com/authorize',
      token_url             => 'https://provider.example.com/token',
      issuer                => 'https://provider.example.com',
      signin_redirect_path  => '/oidc/login/callback',
      logout_redirect_path  => '/oidc/logout/callback',
      end_session_url       => 'https://provider.example.com/logout',
      scope                 => 'openid profile email',
      store_mode            => 'session',
    },
  },
};

my $inner_app = sub {
  my $env = shift;

  if ($env->{PATH_INFO} eq '/protected') {
    if (my $identity = $env->{oidc}->get_valid_identity()) {
      return [200, ['Content-Type' => 'text/plain'], ["Hello " . $identity->subject]];
    }
    $env->{oidc}->redirect_to_authorize();  # dies -> caught by the middleware
  }

  if ($env->{PATH_INFO} eq '/do-logout') {
    $env->{oidc}->redirect_to_logout();     # dies -> caught by the middleware
  }

  return [404, ['Content-Type' => 'text/plain'], ['Not Found']];
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

# ----------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------

test_psgi $app, sub {
  my $cb = shift;

  my ($state, $session_cookie, $cookie_value, $cookie_value2, $cookie_value3, $cookie_value4);

  subtest '1) Unauthenticated access to a protected route -> Redirected to the provider' => sub {
    my $res1 = $cb->(GET '/protected');
    is($res1->code, 302, 'unauthenticated access redirects');

    my $authorize_url = URI->new($res1->header('Location'));
    is($authorize_url->host, 'provider.example.com', 'redirects to the provider host');
    is($authorize_url->path, '/authorize', 'redirects to the authorize endpoint');

    $state = $authorize_url->query_param('state');
    ok($state, 'state parameter is present in the authorize URL');

    $session_cookie = $res1->header('Set-Cookie');
    ok($session_cookie, 'a session cookie has been set');

    ($cookie_value) = $session_cookie =~ /^([^;]+)/;
  };

  subtest '2) Simulate the provider redirecting the browser back to our callback' => sub {
    my $res2 = $cb->(
      GET "/oidc/login/callback?code=some-code&state=$state",
      Cookie => $cookie_value,
    );
    is($res2->code, 302, 'login callback redirects back to the target url');
    is(URI->new($res2->header('Location'))->path, '/protected', 'redirects to the originally requested url');

    ($cookie_value2) = ($res2->header('Set-Cookie') || $session_cookie) =~ /^([^;]+)/;
  };

  subtest '3) Access the protected route again, with the (now authenticated) session' => sub {
    my $res3 = $cb->(GET '/protected', Cookie => $cookie_value2);
    is($res3->code, 200, 'authenticated access succeeds');
    is($res3->content, 'Hello jdoe', 'identity has been correctly stored and retrieved');
  };

  subtest '4) Logout flow' => sub {
    my $res4 = $cb->(GET '/do-logout', Cookie => $cookie_value2);
    is($res4->code, 302, 'logout redirects');
    my $logout_url = URI->new($res4->header('Location'));
    is($logout_url->host, 'provider.example.com', 'redirects to the provider host for logout');
    is($logout_url->path, '/logout', 'redirects to the end_session endpoint');

    my $logout_state = $logout_url->query_param('state');
    ($cookie_value3) = ($res4->header('Set-Cookie') || $cookie_value2) =~ /^([^;]+)/;

    my $res5 = $cb->(
      GET "/oidc/logout/callback?state=$logout_state",
      Cookie => $cookie_value3,
    );
    is($res5->code, 302, 'logout callback redirects');
    ($cookie_value4) = ($res5->header('Set-Cookie') || $cookie_value3) =~ /^([^;]+)/;
  };

  subtest '5) The identity is gone' => sub {
    my $res6 = $cb->(GET '/protected', Cookie => $cookie_value4);
    is($res6->code, 302, 'access is unauthenticated again after logout');
  };
};

done_testing();
