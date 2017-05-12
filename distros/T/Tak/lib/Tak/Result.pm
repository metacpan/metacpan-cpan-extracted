package Tak::Result;

use Moo;

has type => (is => 'ro', required => 1);
has data => (is => 'ro', required => 1);

sub flatten { $_[0]->type, @{$_[0]->data} }

sub is_success { $_[0]->type eq 'success' }

sub get {
  my ($self) = @_;
  $self->throw unless $self->is_success;
  return wantarray ? @{$self->data} : $self->data->[0];
}

sub throw {
  my ($self) = @_;
  die $self->exception;
}

sub exception {
  my ($self) = @_;
  $self->type.': '.join ' ', @{$self->data};
}

1;
