package Pipeline::Segment::Async::Fork;

use strict;
use warnings;

use Data::UUID;
use Pipeline::Segment::Async::Handler;
use base qw( Pipeline::Segment::Async::Handler );

our $VERSION = "3.12";

sub canop { 1 }

sub run {
  my $self = shift;
  my $sub  = shift;
  my @args = @_;
  $self->create_id;
  if (!(my $pid = fork())) {
    require Storable;
    require File::Spec;
    my $results = $sub->( @args );
    Storable::nstore(
		     $results,
		     File::Spec->catfile(
					 File::Spec->tmpdir(),
					 $self->id
					)
		    );
    kill 9, $$;
  } else {
    $self->pid( $pid );
    return;
  }
}

sub create_id {
  my $self = shift;
  my $ug   = Data::UUID->new();
  my $uuid = $ug->create;
  my $id   = $ug->to_string( $uuid );
  $self->id( $id );
}

sub id {
  my $self = shift;
  my $id   = shift;
  if (defined( $id )) {
    $self->{ thread_id } = $id;
    return $self;
  } else {
    return $self->{ thread_id };
  }
}

sub pid {
  my $self = shift;
  my $pid  = shift;
  if (defined( $pid )) {
    $self->{ pid } = $pid;
    return $self;
  } else {
    return $self->{ pid };
  }
}

sub reattach {
  my $self = shift;
  if (waitpid($self->pid, 0) == $self->pid) {
    require Storable;
    require File::Spec;
    my $return = Storable::retrieve(
			      File::Spec->catfile(
						  File::Spec->tmpdir(),
						  $self->id
						 )
			     );
    $self->unlink();
    return $return;
  } else {
    die "cannot wait for pid ". $self->pid;
  }
}

sub discard {
  my $self = shift;
  $self->{ DESTROY_SHOULD_UNLINK } = 1;
}

sub unlink {
  my $self = shift;
  unlink(
	 File::Spec->catfile(
			     File::Spec->tmpdir(),
			     $self->id
			    )
	);
}

sub DESTROY {
  my $self = shift;
  $self->unlink if $self->{ DESTROY_SHOULD_UNLINK };
}


1;
__END__

=head1 NAME

Pipeline::Segment::Async::Fork - fork model for asynchronous pipeline segments

=head1 DESCRIPTION

C<Pipeline::Segment::Async::Fork> provides asynchronous segments under Perl's
forking model.

=head1 SEE ALSO

Pipeline::Segment::Async, Pipeline::Segment::Async::Handler, Pipeline::Segment::Async::IThreads

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

Thie module is released under the same terms as Perl itself.

=cut
