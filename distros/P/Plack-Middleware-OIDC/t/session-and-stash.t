use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::OIDC;

sub build_provider_config {
  my ($store_mode) = @_;

  return {
    id                   => 'app',
    secret               => 'secret',
    authorize_url        => 'https://provider.example.com/authorize',
    token_url            => 'https://provider.example.com/token',
    issuer               => 'https://provider.example.com',
    signin_redirect_path => '/oidc/login/callback',
    store_mode           => $store_mode,
  };
}

subtest 'Session storage requires a session middleware' => sub {
  my $config = {
    provider => {
      app => build_provider_config('session'),
    },
  };

  my $app = builder {
    # Deliberately no Session middleware here.
    enable 'OIDC', config => $config;
    sub {
      return [200, ['Content-Type' => 'text/plain'], ['OK']];
    };
  };

  test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is($res->code, 500, 'internal server error is expected');
    like($res->content,
         qr{no session found in \$env->\{'psgix\.session'\}},
         'expected output');
  }
};

subtest 'Stash storage creates a request scoped oidc.stash hash' => sub {
  my $config = {
    provider => {
      app => build_provider_config('stash'),
    },
  };

  my $app = builder {
    enable 'OIDC', config => $config;
    sub {
      my $env = shift;
      return [200,
              ['Content-Type' => 'text/plain'],
              [ref($env->{'oidc.stash'}) eq 'HASH' ? 'ok' : 'bad']];
    };
  };

  test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/');
    is($res->code, 200, 'stash-mode request succeeds without session middleware');
    is($res->content, 'ok', 'stash is initialized as a hashref');
  };
};

subtest 'The stash is request scoped' => sub {
  my $config = {
    provider => {
      app => build_provider_config('stash'),
    },
  };

  my $app = builder {
    enable 'OIDC', config => $config;
    sub {
      my $env = shift;

      if ($env->{PATH_INFO} eq '/set') {
        $env->{'oidc.stash'}->{marker} = 'present';
        return [200, ['Content-Type' => 'text/plain'], ['set']];
      }

      return [200,
              ['Content-Type' => 'text/plain'],
              [defined $env->{'oidc.stash'}->{marker} ? 'leaked' : 'clean']];
    };
  };

  test_psgi $app, sub {
    my $cb = shift;

    my $res1 = $cb->(GET '/set');
    is($res1->content, 'set', 'first request stores a stash value');

    my $res2 = $cb->(GET '/');
    is($res2->content, 'clean', 'stash does not leak between requests');
  };
};

done_testing;
