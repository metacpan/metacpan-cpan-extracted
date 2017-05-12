package Object::Remote::CodeContainer;

use Moo;

has code => (is => 'ro', required => 1);

sub call {
  my $self = shift;
  $self->code->(@_)
}

1;
