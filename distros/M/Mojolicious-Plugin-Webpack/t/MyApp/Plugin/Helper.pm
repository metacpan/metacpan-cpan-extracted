package t::MyApp::Plugin::Helper;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $config) = @_;
  $app->helper(dummy => sub {'Just a dummy plugin to make sure the t/MyApp/Plugin directory exists'});
}

1;
