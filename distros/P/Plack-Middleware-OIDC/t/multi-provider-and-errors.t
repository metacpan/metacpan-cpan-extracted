use strict;
use warnings;
use utf8;
use Test::More;
use Test::MockModule;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Scalar::Util qw(refaddr);

use Plack::Middleware::OIDC;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestOIDC::Logger;

my $oidc_config = {
  default_provider          => 'provider_a',
  authentication_error_path => '/error',
  provider                  => {
    provider_a => {
      id             => 'app-a',
      secret         => 'secret-a',
      authorize_url  => 'https://a.example.com/authorize',
      token_url      => 'https://a.example.com/token',
      issuer         => 'https://a.example.com',
      signin_redirect_path      => '/oidc/a/login/callback',
      logout_redirect_path      => '/oidc/a/logout/callback',
    },
    provider_b => {
      id             => 'app-b',
      secret         => 'secret-b',
      authorize_url  => 'https://b.example.com/authorize',
      token_url      => 'https://b.example.com/token',
      issuer         => 'https://b.example.com',
      signin_redirect_path => '/oidc/b/login/callback',
      logout_redirect_path => '/oidc/b/logout/callback',
    },
  },
};

my $inner_app = sub {
  my $env = shift;

  if ($env->{PATH_INFO} eq '/check') {
    my $default_provider = $env->{oidc}->client->provider;
    my $same_instance     = refaddr($env->{oidc}) == refaddr($env->{'oidc.provider_a'}) ? 1 : 0;
    my $provider_b_name   = $env->{'oidc.provider_b'}->client->provider;

    return [200, ['Content-Type' => 'text/plain'],
            ["default=$default_provider same=$same_instance b=$provider_b_name"]];
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

subtest q{Default provider's instance} => sub {
  test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/check');
    is($res->code, 200, 'request succeeds');
    is($res->content, 'default=provider_a same=1 b=provider_b',
       '$env->{oidc} matches the default provider, and $env->{"oidc.$provider"} exposes every provider');
  };
};

subtest q{Login callback error must redirect when authentication_error_path is configured} => sub {
  test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/oidc/a/login/callback?code=some-code&state=unknown-state');
    is($res->code, 302, 'authentication error on login callback redirects instead of propagating');
    like($res->header('Location'), qr{/error$}, 'redirects to the configured authentication_error_path');
  };
};

done_testing();
