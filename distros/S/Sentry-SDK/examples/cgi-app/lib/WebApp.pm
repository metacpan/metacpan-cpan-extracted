package WebApp;
use Mojo::Base 'CGI::Application', -signatures;

use CGI::Application::Plugin::Sentry;
use Sentry::SDK;

sub cgiapp_init ($c, @params) {
  $c->param(
    sentry_options => {
      dsn         => 'http://60b58c9d1a604056b75bb15e1775fc40@localhost:9000/3',
      environment => 'my environment',
      release     => '1.0.0',
      dist        => '12345',
      traces_sample_rate => 1,
    }
  );
}

sub cgiapp_prerun ($c, $rm) {
  Sentry::SDK->configure_scope(sub ($scope) {
    $scope->set_user({ id => 12345, name => 'John Doe' });
  });
}

sub setup {
  my $self = shift;
  $self->start_mode('mode1');
  $self->mode_param('rm');
  $self->run_modes(mode1 => 'do_stuff', dies => 'dies');
}

sub do_stuff {
  Sentry::SDK->capture_message('my custom message');
  return 'stuff';
}

sub dies {
  die 'ohoh';
}

1;
