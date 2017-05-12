package POEx::ZMQ::FFI::Callable;
$POEx::ZMQ::FFI::Callable::VERSION = '0.005007';
use Carp ();
use Scalar::Util ();
use strictures 2;

=for Pod::Coverage .*

=cut

sub new {
  bless +{ @_[1 .. $#_] }, $_[0]
}

sub METHODS { keys %{ $_[0] } }
sub FETCH   { $_[0]->{ $_[1] } }
sub EXPORT  { +{ %{ $_[0] } } }


our $AUTOLOAD;

sub can {
  my ($self, $method) = @_;
  if (my $sub = $self->SUPER::can($method)) {
    return $sub
  }
  return unless exists $self->{$method};
  sub {
    if (my $sub = $_[0]->SUPER::can($method)) {
      goto $sub
    }
    $AUTOLOAD = $method;
    goto &AUTOLOAD
  }
}

sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s/.*:://;
  Scalar::Util::blessed($self)
    or Carp::confess "Not a class method: '$method'";

  Carp::confess "Can't locate object method '$method'"
    unless exists $self->{$method};

  $self->{$method}->call(@_)
}

sub DESTROY {}


1;
