package Tak::ObjectProxy;

use strictures 1;

sub AUTOLOAD {
  my $self = shift;
  (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
  $self->{client}->proxy_method_call($self, $method => @_);
}

sub DESTROY {
  my $self = shift;
  $self->{client}->proxy_death($self);
}

1;
