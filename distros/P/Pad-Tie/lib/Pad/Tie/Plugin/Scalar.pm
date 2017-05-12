use strict;
use warnings;

package Pad::Tie::Plugin::Scalar;

use base 'Pad::Tie::Plugin';

sub provides { 'scalar' }

sub scalar {
  my ($plugin, $ctx, $self, $args) = @_;
  my $class = ref($plugin) || $plugin;
  $args = $plugin->canon_args($args);
  for my $method (keys %$args) {
    my $name = $args->{$method};
    tie $ctx->{"\$$name"}, $class, $self, $method;
  }
}

sub TIESCALAR {
  my ($class, $inv, $method) = @_;
  return bless [ $inv, $method ] => $class;
}

sub FETCH {
  my ($self, $method) = @{+shift};
  return $self->$method;
}

sub STORE {
  my ($self, $method) = @{+shift};
  $self->$method(@_);
}

1;
