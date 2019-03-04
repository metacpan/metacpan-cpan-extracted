package RogersMine::Cell;
use Moo;
use strictures;

has risk => (is => 'ro');
has bomb => (is => 'lazy');
has clicked => (is => 'rw', default => sub { 0 });

sub _build_bomb {
  my $self = shift;
  rand() < $self->risk;
}

1;
