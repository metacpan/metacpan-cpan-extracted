package Object::Remote::GlobContainer;
use Moo;
use FileHandle;

has _handle => (is => 'ro', required => 1, init_arg => 'handle');

sub AUTOLOAD {
  my ($self, @args) = @_;
  (my $method) = our $AUTOLOAD =~ m{::([^:]+)$};
  return if $method eq 'DESTROY';
  return $self->_handle->$method(@args);
}

1;
