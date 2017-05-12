package basiccomplex;

use Moose;
extends 'usesrole';

has 'z' => ( isa => 'Int', is => 'rw', required => 1 );

sub clear {
  my $self = shift;
  $self->x(0);
  $self->y(0);
  $self->z(0);
}

1;
