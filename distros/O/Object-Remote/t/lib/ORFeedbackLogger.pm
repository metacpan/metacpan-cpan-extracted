package ORFeedbackLogger;

use Test::More;
use Moo;

extends 'Object::Remote::Logging::Logger';

has feedback_output => (is => 'rw' );
has feedback_input => ( is => 'rw' );

sub reset {
  my ($self) = @_;
  $self->feedback_output(undef);
  $self->feedback_input(undef);

  ok(! defined $self->feedback_output && ! defined $self->feedback_input, 'Reset successful');
}

sub _log {
  my $self = shift;

  $self->feedback_input([@_]);

  $self->SUPER::_log(@_);
}

sub _output {
  my ($self, $rendered) = @_;
  $self->feedback_output($rendered);
}

1;
