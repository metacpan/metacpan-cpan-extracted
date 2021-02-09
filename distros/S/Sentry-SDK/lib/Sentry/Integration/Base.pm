package Sentry::Integration::Base;
use Mojo::Base -base, -signatures;

has 'name';

sub setup_once ($self, $add_global_event_processor, $get_current_hub) {
  die 'needs to be overridden';
}

1;
