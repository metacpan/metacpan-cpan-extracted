package Pipeline::Dispatch;

use strict;
use warnings;

use Pipeline;
use Pipeline::Base;
use base qw( Pipeline::Base );

our $VERSION = "3.12";

sub segments {
  my $self = shift;
  my $list = shift;
  if (defined( $list )) {
    $self->{ segments } = $list;
    return $self;
  } else {
    $self->{ segments } ||= [];
    return $self->{ segments };
  }
}

sub dispatched_segments {
  my $self = shift;
  my $list = shift;
  if (defined( $list )) {
    $self->{ dispatched_segments } = $list;
    return $self;
  } else {
    $self->{ dispatched_segments } ||= [];
    return $self->{ dispatched_segments };
  }
}

sub get {
  my $self = shift;
  my $idx  = shift;
  return $self->segments->[ $idx ];
}

sub add {
  my $self = shift;

  return $self if push(
		       @{$self->segments},
		       grep { $_->isa('Pipeline::Segment') } @_
		      ) == @_;
}

sub delete {
  my $self = shift;
  my $idx  = shift;
  splice(@{$self->segments},$idx,1);
  $self;
}

sub get_next_segment {
  my $self = shift;
  my $pipe = shift;
  my $segment = shift @{$self->segments};
  return $segment;
}

sub dispatch_a_segment {
  my $self = shift;
  my $seg  = shift;
  my $meth = $seg->dispatch_method || $self->dispatch_method;

  $self->emit("dispatching to " . ref($seg));

  $seg->parent->start_dispatch();

  my @results = $seg->$meth( $seg->parent );

  $seg->parent->end_dispatch();

  return @results;
}

sub next {
  my $self = shift;
  my $pipe = shift || Pipeline->new();

  my $segment = $self->get_next_segment( $pipe );

  $segment->prepare_dispatch( $pipe );
  my @results = $self->dispatch_a_segment( $segment );
  $segment->cleanup_dispatch( $pipe );

  push @{$self->dispatched_segments}, $segment;

  return @results;
}

sub dispatch_method {
  my $self = shift;
  my $text = shift;
  if (defined( $text )) {
    $self->{ dispatch_method } = $text;
    return $self;
  } else {
    $self->{ dispatch_method } ||= 'dispatch';
    return $self->{ dispatch_method };
  }
}

sub segment_available {
  my $self = shift;
  !!$self->segments->[0]
}

sub reset {
  my $self = shift;
  $self->segments( $self->dispatched_segments );
  $self->dispatched_segments( [] );
}


1;

=head1 NAME

Pipeline::Dispatch - dispatcher for pipeline segments

=head1 SYNOPSIS

  use Pipeline::Dispatch;
  my $dispatcher = Pipeline::Dispatch->new();
  $dispatcher->segments();
  $dispatcher->add( Pipeline::Segment->new() );
  $dispatcher->delete( 0 );
  $dispatcher->segment_available && $dispatcher->next()
  my $method = $dispatcher->dispatch_method();

=head1 DESCRIPTION

C<Pipeline::Dispatch> simply accepts pipeline segments and does very little
with them.  It can dispatch segments in order, one by one.  It is also capable
of altering the way in which it dispatches to each segment, both on a pipeline
basis, and on a segment-by-segment basis.

=head1 CONSTRUCTOR

=over 4

=item new()

The C<new()> constructor simply returns a new dispatcher object.

=back

=head1 METHODS

=over 4

=item segments( [ARRAYREF] )

The C<segments()> method returns the dispatchers list of remaining segments as an
array reference.  Optionally the ARRAYREF argument can be given to the C<segments()>
method, which will set the list.

=item add( LIST )

The C<add()> method adds one or more segments to the dispatchers segment list.

=item delete( INTEGER )

The C<delete()> method removes the segment at index INTEGER from the list of
segments.

=item segment_available()

The C<segment_available()> method returns true or false, depending on whether or
not there is a segment available to dispatch to.

=item next( [ Pipeline ] )

The C<next()> method dispatches the next segment in the segment list.  It optionally
takes a Pipeline object that is handed down to the segment.

=item dispatch_method( [STRING] )

The C<dispatch_method()> method gets and sets the method name to call globally on
each segment for dispatch.  Individual segments can override this if they set
dispatch_method themselves.

=item dispatched_segments( [ARRAYREF] )

The C<dispatched_segments()> method gets and sets the list of segments that
have already been dispatched.  Used by the C<reset()> method, and probably
should not be called by the user..

=item reset()

<reset()> puts the dispatcher back into an undispatched state - all the segments
are available for dispatch again.

=back

=head1 SEE ALSO

Pipeline::Segment Pipeline

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.

http://opensource.fotango.com

=cut





=cut
