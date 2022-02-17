package BasicApp;
use strict;
use warnings;

use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {
  $self->plugin('OpenAPI::Modern', $self->config->{openapi});
}

1;
