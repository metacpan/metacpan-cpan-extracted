package Mock::Sentry::Hub;
use Mojo::Base -base, -signatures;

has captured_events => sub { [] };

sub capture_event ($self, $transaction) {
  push $self->captured_events->@*, $transaction;
}

1;
