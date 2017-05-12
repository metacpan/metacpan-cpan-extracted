use common::sense;

sub {
  my ($self) = @_;
  delete $self->env->{tt};
  undef;
};
