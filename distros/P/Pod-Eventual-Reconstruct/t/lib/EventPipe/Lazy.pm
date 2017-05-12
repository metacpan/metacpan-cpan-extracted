
use strict;
use warnings;

package EventPipe::Lazy;

use Moo;
use Pod::Eventual::Reconstruct::LazyCut;
extends 'Pod::Eventual';

my $reconstructor;

sub transform_string {
  my ( $class, $source ) = @_;
  my $output;
  $reconstructor = Pod::Eventual::Reconstruct::LazyCut->string_writer($output);
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
