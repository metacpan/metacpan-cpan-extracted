package Pipeline::Segment::Async::IThreads;

use strict;
use warnings;
our $VERSION = "3.12";

BEGIN {
  use Config;
  if ($Config{useithreads}) {
    $Pipeline::Segment::Async::IThreads::AVAILABLE = 1;
    require threads;
    threads->import;
  } else {
    $Pipeline::Segment::Async::IThreads::AVAILABLE = 0;
  }
}

use Config;
use Pipeline::Segment::Async::Handler;
use base qw( Pipeline::Segment::Async::Handler );

sub canop {
  my $self = shift;
  $Pipeline::Segment::Async::IThreads::AVAILABLE
}

sub run {
  my $self = shift;
  my $sub  = shift;
  my @args = @_;
  $self->thread( threads->create( $sub, @args ) );
}

sub thread {
  my $self   = shift;
  my $thread = shift;
  if (defined( $thread )) {
    $self->{ thread } = $thread;
    return $self;
  } else {
    return $self->{ thread };
  }
}

sub reattach {
  my $self = shift;
  return $self->thread->join();
}

sub discard {
  my $self = shift;
  $self->thread->detach();
}

1;

__END__

=head1 NAME

Pipeline::Segment::Async::IThreads - ithread model for asynchronous pipeline segments

=head1 DESCRIPTION

C<Pipeline::Segment::Async::IThreads> provides asynchronous segments under Perl's
ithreads model.

=head1 SEE ALSO

Pipeline::Segment::Async, Pipeline::Segment::Async::Handler, Pipeline::Segment::Async::Fork

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

Thie module is released under the same terms as Perl itself.

=cut
