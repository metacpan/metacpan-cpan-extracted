package Pipeline::Dumper;

use strict;
use warnings;

use Pipeline::Dispatch;
use base qw( Pipeline::Dispatch );

our $VERSION = "3.12";

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->{ indent } = 0;
    return $self;
  }
}

sub dispatch_a_segment {
  my $self = shift;
  my $seg  = shift;
  if ($seg->isa('Pipeline')) {
    $self->next_pipeline( $seg );
  } else {
    $self->next_segment( $seg );
  }
  return 1;
}

sub next_pipeline {
  my $self = shift;
  my $seg  = shift;
  my $pipe = $seg->parent();
  $self->indent;
  $self->print($seg);
  $self->indent;

  ## this sets up the dispatcher in the next pipeline
  $seg->dispatcher(
		   ref($self)->new()
		             ->indent( $self->indent_val )
		             ->segments(
					$seg->dispatcher
					    ->segments
				       )
		  );
  $seg->dispatch();
  $self->undent;
  $self->undent;
}

sub next_segment {
  my $self = shift;
  my $seg  = shift;
  my $pipe = $seg->parent();
  $self->print($seg);
}

sub print {
  my $self = shift;
  my $seg  = shift;
  print "   " x $self->indent_val();
  if ($seg->isa('Pipeline')) { print "> " }
  else { print "| " }
  print ref($seg);
  print "\n";
}

sub indent {
  my $self = shift;
  my $val  = shift;
  if (defined( $val )) {
    $self->{ indent } = $val;
    return $self;
  } else {
    $self->{ indent }++;
  }
}

sub undent {
  my $self = shift;
  $self->{ indent }--;
}

sub indent_val {
  my $self = shift;
  return $self->{ indent };
}


1;

__END__

=head1 NAME

Pipeline::Dumper - tool for dumping a pipeline

=head1 SYNOPSIS

  my $pipeline = Pipeline->new();
  my $dumper   = Pipeline::Dumper->new();
  $pipeline->dispatcher( $dumper );
  $pipeline->dispatch();

=head1 DESCRIPTION

C<Pipeline::Dumper> is a subclassed dispatcher.  It will simply dump the
structure of a pipeline to STDOUT instead of actively executing the pipeline.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same terms as Perl itself.

=cut
