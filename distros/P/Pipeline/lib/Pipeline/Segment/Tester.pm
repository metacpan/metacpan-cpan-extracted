package Pipeline::Segment::Tester;

use strict;
use warnings::register;

use Pipeline;
use Pipeline::Base;
use base qw(Pipeline::Base);
our $VERSION = "3.12";

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->pipe( Pipeline->new() );
    return 1;
  } else {
    return 0;
  }
}

sub pipe {
  my $self = shift;
  my $pipe = shift;
  if (defined($pipe)) {
    $self->{pipe} = $pipe;
    return $self;
  } else {
    return $self->{pipe};
  }
}

sub test {
  my $self = shift;
  my $seg  = shift;

  $self->pipe->add_segment($seg);
  $self->pipe->store->set($_) foreach @_;
  return $self->pipe->dispatch();
#  $self->pipe->debug( 1 ); 
#  return (wantarray) ? ($self->pipe->dispatch) : [$self->pipe->dispatch];
#  return $self->pipe->dispatch();
}

1;

=head1 NAME

Pipeline::Segment::Tester - a test wrapper for a Pipeline::Segment

=head1 SYNOPSIS

  use Pipeline::Segment::Tester;

  my $pst = Pipeline::Segment::Tester->new();
  $pst->test( $segment, $objects, $in, $store );

=head1 DESCRIPTION

C<Pipeline::Segment::Tester> exists to make testing segments easier.  Segments
will often rely on having multiple other objects in a pipeline store to be used
properly, which makes testing a bit icky, as the store and the pipeline need
to be set up to handle testing of a segment.  Pipeline::Segment::Tester removes
this requirement by creating the pipeline and adding stuff to the store for you
before, and making your life easier.

=head1 METHODS

=over 4

=item new()

The C<new> method constructs a new Pipeline::Segment::Tester object and returns it.

=item init()

The C<init> method is called by the constructor and performs construction time initialization
on the object.

=item test( Pipeline::Segment, [ ARRAY ] )

The C<test> method takes a segment object as its first argument, which it will add to its
pipeline before dispatch.  It also takes an infinite number of additional paramaters that
will be added to the store prior to dispatch of the pipeline.

Returns the production of the pipeline.

=item pipe( [ Pipeline ] )

The C<pipe> method gets and sets the Pipeline object that Pipeline::Segment::Tester will use.

=back

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=cut


