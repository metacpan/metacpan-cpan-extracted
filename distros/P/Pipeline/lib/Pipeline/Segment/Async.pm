package Pipeline::Segment::Async;

use strict;
use warnings;

use Pipeline::Segment;
use Pipeline::Error::AsyncResults;
use Pipeline::Segment::Async::Fork;
use Pipeline::Segment::Async::IThreads;

use base qw( Pipeline::Segment );

our $VERSION = "3.12";

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->threading_models(
			    [
			     'Pipeline::Segment::Async::IThreads',
			     'Pipeline::Segment::Async::Fork',
			    ]
			   );
  }
}

sub threading_models {
  my $self = shift;
  my $list = shift;
  if ( defined( $list ) ) {
    $self->{ threading_models_available } = $list;
    return $self;
  } else {
    my $retval = $self->{ threading_models_available };
    if (wantarray()) {
      return @$retval;
    } else {
      return $retval;
    }
  }
}

sub predispatch {
  my $self = shift;
  my $sub  = $self->can('dispatch');
  my $outer = sub {
    my $self = shift;
    my @results = $sub->($self, $self->parent);
    return [$self, [ @results ]];
  };
  $self->model->run( $outer, $self );
  $self->place_in_store();
  return 1;
}

sub place_in_store {
  my $self = shift;
  $self->store->set( $self );
}

sub model {
  my $self = shift;
  my $obj  = shift;
  if (defined( $obj )) {
    $self->{ threading_model } = $obj;
    return $self;
  } else {
    $self->{ threading_model } ||= $self->determine_threading_model();
    return $self->{ threading_model };
  }
}

sub determine_threading_model {
  my $self = shift;
  foreach my $model ($self->threading_models) {
    if ( $model->canop() ) {
      return $model->new();
    }
  }
  return undef;
}

sub reattach {
  my $self = shift;
  my $results = $self->model->reattach;
  if (defined($results) && ref($results) eq 'ARRAY') {
    return @{ $results->[1] };
  } else {
    throw Pipeline::Error::AsyncResults;
  }
}

sub discard {
  my $self = shift;
  $self->model->discard;
}

sub dispatch_method {
  return "predispatch";
}

1;

__END__

=head1 NAME

Pipeline::Segment::Async - asynchronous pipeline segments

=head1 SYNOPSIS

  my $seg = $pipe->store->get( $async_segment_classname );
  my $ret = $seg->reattach();

=head1 DESCRIPTION

The C<Pipeline::Segment::Async> module allows you to write asynchronous pipeline
segments.  Whenever an asynchronous segment is dispatched it places itself in the
store, and splits away from the main process that keeps running. At any point furthe
down the pipeline you can request the segment from the store, and then ask it to
give you back its return values by calling the C<reattach()> method, or even, throw
them away by calling C<discard()> which will simply destroy the segment when it
completes.  If you call C<discard()> there is no way you can get it
back.

You add any asynchronous segment to the a pipeline in exactly the same manner you
would add any other segment.  It gets dispatched in the normal way, with the normal
arguments supplied to the dispatch method.  Getting objects from the store will
retrieve them as expected. however altering those objects or setting them back into
the store will not do what you expect.

C<Pipeline::Segment::Async> works by indicating to the dispatcher that it wants a
different method to be its dispatch method. If you indicate to the dispatcher that
you want something to dispatch different at the segment level, then your
asynchronous segment will be come decidedly synchronous.

C<Pipeline::Segment::Async> inherits from C<Pipeline::Base> and has any methods that
it provides.

=head1 METHODS

=over 4

=item init()

C<init()> is called by the constructor, and sets up the list of threading models that
C<Pipeline::Segment::Async> is aware of.  See C<threading_models()> for more information.

=item threading_models( [ARRAYREF] )

C<threading_models()> gets and sets a list of classes that know how to process segements
asynchronously.

=item predispatch()

C<predispatch()> is called by the pipeline dispatcher and prepares the segment for asynchronous
execution.

=item model( [Pipeline::Segment::Async::*] )

C<model()> returns an object that represents the threading model that C<Pipeline::Segment::Async>
will call. If it does not yet have an object a call to C<determine_threading_model()> is called.

=item determine_threading_model()

C<determine_threading_model()> will look at all the classes in the list provided by
C<threading_models()> and determine if they can operate under the current configuration.  It will
return an object of one of those classes, provided it can operate.

=item reattach()

C<reattach()> takes a detached asynchronous segment and joins it back, placing the results in
the correct area of the pipeline.

=item discard()

C<discard()> flags an asynchronous segment as never needing to be reattached.

=item dispatch_method()

C<dispatch_method()> tells the pipeline dispatch class which method to call in order to dispatch
this class.  In the case of C<Pipeline::Segment::Async> it returns a constant with the value
I<predispatch>.

=back

=head1 SEE ALSO

Pipeline::Segment, Pipeline::Dispatch, Pipeline::Base, Pipeline::Segment::Async::Handler

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.

=cut

