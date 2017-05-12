
use strict;
use warnings;

package EventsToList;

use Moo;

extends 'Pod::Eventual';

my $output;

sub transform_string {
  my ( $class, $source ) = @_;
  $output = [];
  $class->read_string($source);
  return $output;
}

sub handle_event {
  my ( $self, $event ) = @_;
  push @$output, $event;
}

sub handle_blank {
  my ( $self, $event ) = @_;
  push @$output, $event;
}

sub handle_nonpod {
  my ( $self, $event ) = @_;
  push @$output, $event;
}

1;
