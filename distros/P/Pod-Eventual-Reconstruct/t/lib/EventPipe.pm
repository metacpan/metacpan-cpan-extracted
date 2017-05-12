
use strict;
use warnings;

package EventPipe;

use Moo;
use Pod::Eventual::Reconstruct;
extends 'Pod::Eventual';

my $reconstructor;

sub transform_string {
  my ( $class, $source ) = @_;
  my $output;
  $reconstructor = Pod::Eventual::Reconstruct->string_writer($output);
  $class->read_string($source);
  return $output;
}

sub handle_event {
  my ( $self, $event ) = @_;
  $reconstructor->write_event($event);
}

sub handle_blank {
  my ( $self, $event ) = @_;
  $reconstructor->write_event($event);
}

sub handle_nonpod {
  my ( $self, $event ) = @_;
  $reconstructor->write_event($event);
}

1;
