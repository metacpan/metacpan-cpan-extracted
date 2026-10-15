use strict;
use warnings;
use utf8;
use Test::More;

use Plack::Middleware::OIDC;
use Plack::Middleware::OIDC::Logger;

my $middleware;

$middleware = Plack::Middleware::OIDC->new(
  app => sub {
    my ($env) = @_;

    # Simulate a log message emitted during request processing
    $middleware->{_oidc_log}->info('OIDC logger test');

    return [200, ['Content-Type' => 'text/plain'], ['OK']];
  },
);

# Avoid creating actual OIDC clients: this test focuses on logging
$middleware->{_oidc_log} = Plack::Middleware::OIDC::Logger->new();
$middleware->{_oidc_config} = {};
$middleware->{_oidc_client_by_provider} = {};
$middleware->{_oidc_path_map} = {};

sub build_env {
  my ($psgi_logger) = @_;

  return {
    REQUEST_METHOD    => 'GET',
    PATH_INFO         => '/',
    SCRIPT_NAME       => '',
    QUERY_STRING      => '',
    SERVER_NAME       => 'localhost',
    SERVER_PORT       => 5000,
    SERVER_PROTOCOL   => 'HTTP/1.1',
    'psgi.url_scheme' => 'http',
    'psgi.input'      => do {
      open my $fh, '<', '';
      $fh;
    },
    'psgix.logger' => $psgi_logger,
  };
}

subtest 'With psgix.logger' => sub {

  my @logged_messages;
  my $psgi_logger = sub {
    my ($message) = @_;
    push @logged_messages, $message;
  };

  my $env = build_env($psgi_logger);

  # Capture STDERR to ensure the fallback logger is not used
  my $stderr = '';
  my $response;

  {
    local *STDERR;
    open STDERR, '>', \$stderr or die "Cannot capture STDERR: $!";

    $response = $middleware->call($env);
  }

  is($response->[0], 200, 'request completed successfully');

  is(scalar @logged_messages, 1, 'one message sent to psgix.logger');

  is(
    $logged_messages[0]->{level},
    'info',
    'PSGI logger received the expected level',
  );

  is(
    $logged_messages[0]->{message},
    'OIDC logger test',
    'PSGI logger received the expected message',
  );

  is($stderr, '', 'nothing was written to STDERR');
};

subtest 'Without psgix.logger' => sub {

  my $env = build_env(undef);

  # Capture STDERR to ensure the fallback logger is used
  my $stderr = '';
  my $response;

  {
    local *STDERR;
    open STDERR, '>', \$stderr or die "Cannot capture STDERR: $!";

    $response = $middleware->call($env);
  }

  is($response->[0], 200, 'request completed successfully');

  like($stderr,
       qr/^\[info\] OIDC logger test\n$/,
       'one log message written to STDERR');
};

done_testing();
