use strict;
use warnings;
use utf8;
use Test::More;
use Test::MockModule;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use JSON::PP qw(encode_json decode_json);

use OIDC::Client::Plugin;
use Plack::Middleware::OIDC;
use Plack::Middleware::OIDC::Redirect;

my $captured;

my $mock_plugin = Test::MockModule->new('OIDC::Client::Plugin');
$mock_plugin->redefine('new' => sub {
  my ($class, %args) = @_;
  $captured = \%args;

  # Only methods needed by the middleware/application in this test
  return bless {
    client => $args{client},
  }, $class;
});

my $config = {
  default_provider => 'provider',
  provider => {
    provider => {
      id                   => 'app',
      secret               => 'secret',
      authorize_url        => 'https://provider.example.com/authorize',
      token_url            => 'https://provider.example.com/token',
      issuer               => 'https://provider.example.com',
      signin_redirect_path => '/oidc/login/callback',
      store_mode           => 'stash',
    },
  },
};

my $app = builder {
  enable 'OIDC', config => $config;
  sub {
    my $env = shift;

    if ($env->{PATH_INFO} eq '/redirect') {
      die Plack::Middleware::OIDC::Redirect->new(
        url => 'https://provider.example.com/authorize',
      );
    }

    if ($env->{PATH_INFO} eq '/unexpected-error') {
      die "Unexpected internal failure\n";
    }

    return [
      200,
      ['Content-Type' => 'application/json'],
      [encode_json({
        query_value  => $captured->{request_params}{foo},
        query_multi  => $captured->{request_params}{multi},
        header_value => $captured->{request_headers}{'X-Test-Header'},
        base_url     => $captured->{base_url},
        current_url  => $captured->{current_url},
      })],
    ];
  };
};

subtest 'Captured OIDC plugin arguments are correct' => sub {
  test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(
      GET '/check?foo=bar&multi=one&multi=two',
      'X-Test-Header' => 'header-value',
    );

    is($res->code, 200, 'request data test succeeds');

    my $data = decode_json($res->content);

    is($data->{query_value}, 'bar', 'single query parameter is passed as a scalar');
    is_deeply(
      $data->{query_multi},
      ['one', 'two'],
      'multi-valued query parameter is passed as an arrayref',
    );
    is(
      $data->{header_value},
      'header-value',
      'request headers are passed to the plugin',
    );

    is(
      $data->{base_url},
      'http://localhost/',
      'plugin receives the request base URL',
    );

    is(
      $data->{current_url},
      'http://localhost/check?foo=bar&multi=one&multi=two',
      'plugin receives the complete current URL',
    );
  };
};

subtest 'HTTPS public URL is preserved in OIDC plugin arguments' => sub {
  my $https_app = sub {
    my $env = shift;

    $env->{'psgi.url_scheme'} = 'https';
    $env->{SERVER_NAME} = 'www.example.com';
    $env->{SERVER_PORT} = 443;
    $env->{HTTP_HOST} = 'www.example.com';

    return $app->($env);
  };

  test_psgi $https_app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/protected?foo=bar');

    is($res->code, 200, 'HTTPS request succeeds');

    my $data = decode_json($res->content);

    is(
      $data->{base_url},
      'https://www.example.com/',
      'plugin receives the public HTTPS base URL',
    );

    is(
      $data->{current_url},
      'https://www.example.com/protected?foo=bar',
      'plugin receives the complete public HTTPS request URL',
    );
  };
};

subtest 'only OIDC redirect exceptions become redirects' => sub {
  test_psgi $app, sub {
    my $cb = shift;

    # The middleware's internal redirect exception must become HTTP 302.
    my $redirect_res = $cb->(GET '/redirect');

    is(
      $redirect_res->code,
      302,
      'OIDC redirect exception becomes an HTTP redirect',
    );

    is(
      $redirect_res->header('Location'),
      'https://provider.example.com/authorize',
      'redirect response preserves the target URL',
    );

    # An unexpected exception must propagate instead of becoming a redirect.
    my $error_res = $cb->(GET '/unexpected-error');

    is(
      $error_res->code,
      500,
      'unexpected application exception -> internal server error',
    );

    ok(
      !$error_res->header('Location'),
      'no redirect',
    );
  };
};

done_testing;
