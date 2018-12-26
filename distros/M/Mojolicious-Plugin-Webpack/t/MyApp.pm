package t::MyApp;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  unshift @{$self->plugins->namespaces}, 't::MyApp::Plugin';
  $self->plugin('Webpack', {shim => 1});
}

1;
