package basicsimple;

use Moose;

has 'x' => ( isa => 'Int', is => 'rw', required => 1 );
has 'y' => ( isa => 'Int', is => 'rw', required => 1 );

sub clear {
  my $self = shift;
  $self->x(0);
  $self->y(0);
}

1;
