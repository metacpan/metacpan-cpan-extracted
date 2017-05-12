package Plack::Middleware::Scrutiny::IOWrap;

use strict;

=head1 NAME

Plack::Middleware::Scrutiny::IOWrap - Wrap IO Handles

=head1 DESCRIPTION

The child needs to be sent the environment, but C<$env> has some IO handle-like thingts that aren't so easy to serialize. [editors note: WHY do we have to send it back and forth? Can we just fork with it?]. So the parent replaces those with an instance of C<Plack::Middleware::Scrutiny::IOWrap>, which just transmits the result of the methods accross the pipe.

=cut

sub new {
  my $class = shift;
  my $self = {@_};
  return bless $self, $class;
}

sub read {
  my ($self, $buf, $len, $offset) = @_;
  $self->{manager}->send( to_parent => read => [$len, $offset] );
  my ($cmd, $val) = $self->{manager}->receive('from_parent');
    # require Enbugger;
    # Enbugger->stop;
  my ($bufval, $retval) = @$val;
  $_[1] = $bufval;
  return $retval;
}

sub seek {
  my ($self, $position, $whence) = @_;
  $self->{manager}->send( to_parent => seek => [$position, $whence] );
  my ($cmd, $val) = $self->{manager}->receive('from_parent');
    # require Enbugger;
    # Enbugger->stop;
  my ($retval) = @$val;
  return $retval;
}

1;

