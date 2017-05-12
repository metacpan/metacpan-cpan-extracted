package Foo::Bar;
use Mojo::Base 'Mojolicious';

sub overload_cfg_for_site {
  my $self = shift;
  my $config_files = shift;
  $self->plugin('INIConfig::Extended', {
     base_config => $self->app->config,
    config_files => $config_files });
  return;
}

# sub new {
#   my $class = shift;
#   return bless {}, $class;
# }

1;

