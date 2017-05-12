package Pipeline::Analyser;

use strict;

use IO::Handle;
use Pipeline::Base;
use base qw( Pipeline::Base );

our $VERSION = "3.12";

sub init {
  my $self = shift;
  if ($self->SUPER::init()) {
    $self->level( 0 );
    $self->spacing( 4 );
    $self->handle( \*STDOUT );
    return 1;
  }
  return 0;
}

sub handle {
  my $self = shift;
  if (@_) {
    $self->{ handle } = shift;
    return $self;
  }
  return $self->{ handle };
}

sub increment_level {
  my $self  = shift;
  my $level = $self->level();
  $level++;
  $self->level( $level );
}

sub decrement_level {
  my $self = shift;
  my $level = $self->level();
  if ($level != 0 ) {
    $level--;
  }
  $self->level( $level );
}

sub enter {
  my $self = shift;
  $self->handle->print(" " x (($self->level - 1) * $self->spacing));
  $self->handle->print(">" x $self->spacing);
  $self->handle->print("| [ pipeline enter ]\n");
}

sub leave {
  my $self = shift;
  $self->handle->print(" " x (($self->level - 1) * $self->spacing));
  $self->handle->print("|");
  $self->handle->print("<" x $self->spacing);
  $self->handle->print(" [ pipeline exit ]\n");
}

sub level {
  my $self = shift;
  if (@_) {
    $self->{ level } = shift;
    return $self;
  }
  return $self->{ level };
}

sub do_with_segment {
  my $self = shift;
  my $seg  = shift;
  my $name = $self->get_segment_name( $seg );
  $self->handle->print(" " x (($self->spacing * $self->level)));
  $self->handle->print("o) ");
  $self->handle->print($name);
  $self->handle->print("\n");
}

sub spacing {
  my $self  = shift;
  if (@_) {
    $self->{space} = shift;;
    return $self;
  }
  return $self->{space};
}

sub get_segment_name {
  my $self = shift;
  my $seg  = shift;
  return ref( $seg );
}

sub analyse {
  my $self     = shift;
  my $pipeline = shift;

  $self->increment_level();
  $self->enter();

  foreach my $segment (@{ $pipeline->segments }) {
    next unless defined( $segment );
    if ($segment->isa('Pipeline')) {
      $self->increment_level();
      $self->analyse( $segment );
      $self->decrement_level();
    } else {
      $self->do_with_segment( $segment )
    }
  }

  $self->leave( -1 );
  $self->decrement_level();
}

=head1 NAME

Pipeline::Analyser - a small tool for viewing a pipeline

=head1 SYNOPSIS

  use Pipeline::Analyser;
  my $analyser = Pipeline::Analyser->new();
  $analyser->analyse( $my_pipeline_object );

=head1 DESCRIPTION

C<Pipeline::Analyser> is a tool for viewing a pipeline and its segments.

=cut


1;
