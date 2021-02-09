package Sentry::Stacktrace;
use Mojo::Base -base, -signatures;

use Sentry::Stacktrace::Frame;

has exception => undef;

has frame_filter => sub {
  sub {0}
};

has frames => sub ($self) { return $self->prepare_frames() };

sub prepare_frames ($self) {
  my @frames = reverse map { Sentry::Stacktrace::Frame->from_caller($_->@*) }
    $self->exception->frames->@*;

  return [grep { $self->frame_filter->($_) } @frames];
}

sub TO_JSON ($self) {
  return { frames => $self->frames };
}

1;
