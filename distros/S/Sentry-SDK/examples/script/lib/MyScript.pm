package MyScript;
use Mojo::Base -base, -signatures;

use Mojo::Util 'dumper';
use MyIntegration;
use MyLib;
use Sentry::SDK;
use Sentry::Hub;
use Sentry::Severity;
use Try::Tiny;

Sentry::SDK->init({
  dsn          => 'http://b61a335479ff48529d773343287bcdad@localhost:9000/2',
  environment  => 'my environment',
  release      => '1.0.0',
  dist         => '12345',
  integrations => [MyIntegration->new],
  debug        => 1,
});

sub main {
  Sentry::SDK->configure_scope(sub ($scope) {
    $scope->set_tag(foo => 'bar');
  });
  Sentry::SDK->configure_scope(sub ($scope) {
    $scope->set_tag(bar => 'baz');
  });
  Sentry::SDK->add_breadcrumb({
    message => 'my breadcrumb (warning)',
    level   => Sentry::Severity->Warning,
  });

  # # Integration SDK
  # my $hub = Sentry::Hub->get_current_hub();
  # $hub->with_scope(sub {
  #   my $scope = shift;
  #   $scope->set_extra(arguments => [1, 2, 3]);
  #   $scope->add_breadcrumb({
  #     type     => 'navigation',
  #     category => 'navigation',
  #     data     => {from => '/a', to => '/b'}
  #   });
  #   $hub->capture_message('ich bin eine SDK integration message');
  # });

  # Sentry::SDK->capture_message('ich bin eine separate message');

  my $transaction = Sentry::SDK->start_transaction(
    {
      name    => 'MyScript',
      op      => 'http.server',
      request => { url => '/foo/bar', query => { bla => 'blubb' } }
    },
  );
  Sentry::SDK->configure_scope(sub ($scope) {
    $scope->set_span($transaction);
  });
  try {
    my $s = MyLib->new(foo => 'my foo');
    $s->foo1('foo1 value');
  } catch {
    Sentry::SDK->capture_exception($_);
  };

  $transaction->set_http_status(200);
  $transaction->finish();
}

1;
