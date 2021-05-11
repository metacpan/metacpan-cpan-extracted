package Sentry::Integration::Base;
use Mojo::Base -base, -signatures;

has 'name';
has initialized => 0;

sub setup_once ($self, $add_global_event_processor, $get_current_hub) {
  die 'needs to be overridden';
}

1;
