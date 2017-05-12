package Pipeline;

use strict;
use warnings::register;

use Pipeline::Segment;
use Pipeline::Dispatch;
use Pipeline::Store::Simple;
use Scalar::Util qw( blessed weaken );
use base qw( Pipeline::Segment );

our $VERSION = "3.12";

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->debug( 0 );
    $self->store( Pipeline::Store::Simple->new() );
    $self->dispatcher( Pipeline::Dispatch->new() );
    $self->segments( [] );
    return $self;
  } else {
    return undef;
  }
}

sub add_segment {
  my $self = shift;
  $self->dispatcher->add( @_ );
  $self;
}

sub get_segment {
  my $self = shift;
  my $idx  = shift;
  return $self->dispatcher()->get( $idx );
}

sub del_segment {
  my $self = shift;
  my $idx  = shift;
  my $seg = $self->segments()->[ $idx ];
  $self->dispatcher()->delete( $idx );
  $seg;
}

sub segments {
  my $self = shift;
  return $self->dispatcher()->segments( @_ );
}

sub dispatch {
  my $self = shift;

  my $result = $self->dispatch_loop();
  my $cleanup_result = $self->cleanup;

  $self->dispatcher()->reset();

  if (blessed( $result )) {
    return $result->isa('Pipeline::Production') ?
      $result->contents :
      $result || 1;
  } else {
    return $result || 1;
  }
}

sub start_dispatch {
  my $self = shift;
  $self->store->start_transaction;
}

sub end_dispatch {
  my $self = shift;
  $self->store->end_transaction;
}

sub process_indv_result {
  my $self = shift;
  my $thing = shift;
  my $production = undef;
  return $production unless blessed( $thing );
  if ($thing->isa( 'Pipeline::Segment' )) {
    $self->cleanups->add_segment( $thing );
  } elsif ($thing->isa('Pipeline::Production')) {
    $production = $thing;
    $self->store->set( $thing->contents );
  } else {
    $self->store->set( $thing );
  }
  return $production || undef;
}

sub process_results {
  my $self = shift;
  my $args = shift;
  my $final;
  foreach my $result ( @$args ) {
    my $product = $self->process_indv_result( $result );
    $final = $product if $product;
  }
  return $final if $final;
  return undef;
}

sub dispatch_loop {
  my $self = shift;

  ## turn on debugging for the dispatcher if we need to
  $self->dispatcher->debug( $self->debug );

  while($self->dispatcher->segment_available) {
    my $unrefined = [ $self->dispatcher->next( $self ) ];
    my $refined   = $self->process_results( $unrefined );
    if (defined( $refined )) {
      return $refined
    }
  }
  return 1;
}

## be careful here
sub cleanup {
  my $self = shift;
  if ($self->{ cleanup_pipeline }) {
    return (
	    $self->{ cleanup_pipeline }->debug( $self->debug || 0 )
                                       ->parent( $self )
                                       ->store( $self->store() )
                                       ->dispatch()
	   );
  }
#  $self->end_dispatch();
}

sub dispatcher {
  my $self = shift;
  my $obj  = shift;
  if (defined( $obj )) {
    $self->{ dispatcher } = $obj;
    return $self;
  } else {
    return $self->{ dispatcher };
  }
}

sub cleanups {
  my $self = shift;
  $self->{ cleanup_pipeline } ||= ref($self)->new();
}

sub debug {
  my $self = shift;
  $self->SUPER::debug( @_ );
}

sub debug_all {
  my $self  = shift;
  my $debug = shift;
  foreach my $segment (@{ $self->segments }) {
    $segment->isa( 'Pipeline' )
      ? $segment->debug_all( $debug )
      : $segment->debug( $debug );
  }

  $self->debug( $debug );
}

1;

=head1 NAME

Pipeline - Generic pipeline interface

=head1 SYNOPSIS

  use Pipeline;
  my $pipeline = Pipeline->new();
  $pipeline->add_segment( @segments );
  $pipeline->dispatch();

=head1 DESCRIPTION

C<Pipelines> are a mechanism to process data. They are designed to
be plugged together to make fairly complex operations act in a
fairly straightforward manner, cleanly, and simply.

=head1 USING THE PIPELINE MODULE

The usage of the generic pipeline module is fairly simple. You
instantiate a Pipeline object by using the I<new()> constructor.

Segments can be added to the pipeline with the add_segment method.

The store that the Pipeline will use can be set by calling the
I<store()> method later on.  If a store is not set by the time
a pipeline is executing then it will use a store of the type
C<Pipeline::Store::Simple>.

To start the pipeline running call the I<dispatch()> method on your
Pipeline object.

If a segment returns a Pipeline::Production object then the pipeline
will be terminated early and the production will be returned to the
user.  Regardless of when the pipeline is terminated the pipeline's
cleanup pipeline is executed.  Segments can be added to the cleanup
pipeline either explicitly by calling the cleanups method to get the
cleanup pipeline and then adding the segment, or implicitly by
returning a segment object from a segment.

To see what is being dispatched within a pipeline dispatch set the
pipeline's debug_all value to true.

=head2 INHERITANCE

Pipelines are designed to be inherited from.  The inheritance tree is
somewhat warped and should look a little like this:

     MySegment --> Pipeline::Segment <--- Pipeline

In other words, everything is a pipeline segment.

=head1 METHODS

The Pipeline class inherits from the C<Pipeline::Segment> class and
therefore also has any additional methods that its superclass may have.

=over 4

=item init( @_ )

Things to do at construction time.  If you do override this, it will
often be fairly important that you call and check the value of
$self->SUPER::init(@_) to make sure that the setup is done correctly.
Returns itself on success, undef on failure.  The  constructor will
fail if you return a false value.

=item add_segment( LIST )

Adds a segment or segments to the pipeline.  Returns itself.

=item get_segment( INTEGER )

Returns the segment located at the index specified by INTEGER

=item del_segment( INTEGER )

Deletes and returns the segment located at the index specified
by INTEGER

=item process_results( ARRAYREF )

Examines each result of a segment and calls process_indv_result with
each element of ARRAYREF.  In the case that process_indv_result returns
a production then it is returned to the caller.

=item process_indv_result( SCALAR )

Examines a single result and does the appripriate thing with it (ie, if it
is an object it puts it into the store, if it is a production it returns
it to the caller, and if it is a simple value it gets thrown away.  In
the case that a value is returned from process_indv_result the pipeline
should terminate.

=item dispatch()

Starts the pipeline execution.  It calls process_results on anything
that a segment returns.  The pipeline always returns the production
or true.

=item dispatch_loop( Pipeline, [ ARRAYREF ] )

The C<dispatch_loop> method performs the processing for the pipeline

=item start_dispatch

Prepares all elements of the pipeline to begin processing a segment.

=item end_dispatch

Cleans up all elements of the pipeline after processing a segment.

=item dispatch_segment( Pipeline::Segment )

The C<dispatch_segment> method handles the execution of an individual
segment object.

=item dispatcher( [Pipeline::Dispatch] )

The C<dispatcher> method gets and sets the pipeline dispatcher object
that will be used to traverse the pipeline.

=item cleanups()

Returns the cleanup pipeline.  This is a pipeline in and of itself,
and all the methods you can call on a pipeline can also be called on
this.

=item cleanup()

Calls the dispatch method on the cleanup pipeline.

=item segments( [ value ] )

C<segments> gets and sets the value of the pipeline list.  At
initialization this is set to an array reference.

=item debug_all( value )

Sets debug( value ) recursively for each segment in this pipeline.

=back

=head1 SEE ALSO

C<Pipeline::Segment>, C<Pipeline::Store>, C<Pipeline::Store::Simple>
C<Pipeline::Production>, C<Pipeline::Dispatch>

=head1 AUTHORS

  James A. Duncan <jduncan@fotango.com>
  Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd.
Licensed under the same terms as Perl itself.

=cut

