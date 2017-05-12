package basicrole;
use Moose::Role;

sub not_equal_to {
  my( $self, $other ) = @_;
  not $self->equal_to($other);
}

1;
