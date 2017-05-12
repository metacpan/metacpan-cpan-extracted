package Object::Remote::Proxy;

use strictures 1;
use Carp qw(croak);

sub AUTOLOAD {
  my $self = shift;
  (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
  my $to_fire = $self->{method};
  if ((caller(0)||'') eq 'start') {
    $to_fire = "start::${to_fire}";
  }

  unless ($self->{remote}->is_valid) {
    croak "Attempt to use Object::Remote::Proxy backed by an invalid handle";
  }

  $self->{remote}->$to_fire($method => @_);
}

sub DESTROY { }

1;
