use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use URI;

use Plack::Middleware::OIDC;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestOIDC::Logger;

my $oidc_config = {
  provider => {
    my_provider => {
      id                   => 'my-app-id',
      secret               => 'my-app-secret',
      authorize_url        => 'https://provider.example.com/authorize',
      token_url            => 'https://provider.example.com/token',
      issuer               => 'https://provider.example.com',
      end_session_url      => 'https://provider.example.com/logout',
      signin_redirect_path => '/oidc/login/callback',
      logout_redirect_path => '/oidc/logout/callback',
      logout_with_id_token => 0,
    },
  },
};

my @executed_after_redirect;

my $inner_app = sub {
  my $env = shift;

  if ($env->{PATH_INFO} eq '/protected') {
    $env->{oidc}->get_valid_identity()
      or $env->{oidc}->redirect_to_authorize();
    push @executed_after_redirect, 'authorize';
    return [200, ['Content-Type' => 'text/plain'], ['secret']];
  }

  if ($env->{PATH_INFO} eq '/logout') {
    $env->{oidc}->redirect_to_logout();
    push @executed_after_redirect, 'logout';
    return [200, ['Content-Type' => 'text/plain'], ['secret']];
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

test_psgi $app, sub {
  my $cb = shift;

  subtest 'redirect_to_authorize() / redirect_to_logout() must stop the execution of the application' => sub {
    my $res1 = $cb->(GET '/protected');
    is($res1->code, 302, 'unauthenticated access is redirected');
    is(URI->new($res1->header('Location'))->host, 'provider.example.com', 'to the provider');
    is($res1->content, '', 'the redirect response has no body');

    my $res2 = $cb->(GET '/logout');
    is($res2->code, 302, 'logout is redirected');
    is(URI->new($res2->header('Location'))->path, '/logout', 'to the end_session endpoint');

    is_deeply(\@executed_after_redirect, [], 'code placed after the redirect calls never ran');
  };
};

done_testing();
