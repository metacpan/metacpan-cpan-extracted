use strict;
use warnings;
use utf8;
use Test::More;
use Try::Tiny;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::OIDC;

sub provider_config {
  my ($name) = @_;

  return {
    id                    => "app-$name",
    secret                => "secret-$name",
    authorize_url         => "https://$name.example.com/authorize",
    token_url             => "https://$name.example.com/token",
    issuer                => "https://$name.example.com",
    signin_redirect_path  => "/oidc/$name/login/callback",
    logout_redirect_path  => "/oidc/$name/logout/callback",
  };
}

subtest 'A single configured provider is implicitly the default provider' => sub {
  my $config = {
    provider => {
      only => provider_config('only'),
    },
  };

  my $app = builder {
    enable 'Session';
    enable 'OIDC', config => $config;
    sub {
      my $env = shift;
      return [
        200,
        ['Content-Type' => 'text/plain'],
        [
          defined($env->{oidc}) &&
          $env->{'oidc.only'} &&
          $env->{oidc} == $env->{'oidc.only'} ? 'ok'
                                              : 'bad'
        ],
      ];
    };
  };

  test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is($res->code, 200, 'single-provider request succeeds');
    is($res->content, 'ok', 'single provider is implicitly the default');
  };
};

subtest 'With several providers and no default_provider, named instances are still exposed' => sub {
  my $config = {
    provider => {
      a => provider_config('a'),
      b => provider_config('b'),
    },
  };

  my $app = builder {
    enable 'Session';
    enable 'OIDC', config => $config;
    sub {
      my $env = shift;
      return [
        200,
        ['Content-Type' => 'text/plain'],
        [
          !defined($env->{oidc}) && $env->{'oidc.a'}
                                 && $env->{'oidc.b'} ? 'ok' : 'bad'
        ],
      ];
    };
  };

  test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is($res->code, 200, 'multi-provider request succeeds without default');
    is($res->content, 'ok',
       'named providers are exposed and no default shortcut is created');
  };
};

subtest 'Inexisting default_provider' => sub {
  my $config = {
    provider => {
      a => provider_config('a'),
      b => provider_config('b'),
    },
    default_provider => 'c',
  };

  my $middleware = Plack::Middleware::OIDC->new(config => $config);

  my $error;
  try {
    $middleware->prepare_app;
  }
  catch {
    $error = $_;
  };

  like($error,
       qr{default_provider 'c' is not configured},
       'expected error message');
};

subtest 'Two different providers must not claim the same callback path' => sub {
  my $config = {
    provider => {
      a => {
        %{ provider_config('a') },
        signin_redirect_path => '/oidc/shared/callback',
      },
      b => {
        %{ provider_config('b') },
        signin_redirect_path => '/oidc/shared/callback',
      },
    },
  };

  my $middleware = Plack::Middleware::OIDC->new(config => $config);

  my $error;
  try {
    $middleware->prepare_app;
  }
  catch {
    $error = $_;
  };

  like($error,
       qr{path '/oidc/shared/callback' is already used},
       'expected error message');
};

subtest 'login and logout cannot share the same callback path' => sub {
  my $config = {
    provider => {
      a => {
        %{ provider_config('a') },
        logout_redirect_path => '/oidc/a/login/callback',
      },
    },
  };

  my $middleware = Plack::Middleware::OIDC->new(config => $config);

  my $error;
  try {
    $middleware->prepare_app;
  }
  catch {
    $error = $_;
  };

  like($error,
       qr{path '/oidc/a/login/callback' is already used},
       'expected error message');
};

done_testing;
