package Tester;
use Mojo::Base 'Mojolicious', -signatures;
sub startup ($self) {
  $self->secrets(['AAAAAAAAAAABBBBBBBBBBBBBBCCCC']);
  $self->plugin(YamlRoutes => { directory => 'config/routes/' }) if $ENV{TEST_DIR};
  $self->plugin(YamlRoutes => { file => 'config/routes/test.yaml' }) if $ENV{TEST_FILE};
}

1;
