package POE::Component::DirWatch::Role::AIO;

our $VERSION = "0.300004";

use POE;
use IO::AIO qw/2/;
use POE::Component::AIO { no_auto_export => 1, no_auto_bootstrap => 1 };
use Moose::Role;
use Path::Class qw(file dir);

has aio => (
  is => 'ro',
  isa => 'POE::Component::AIO',
  required => 1,
  clearer => 'clear_aio',
  default => sub { POE::Component::AIO->new }
);

after _start => sub {
  my $self = $_[OBJECT];
  my $aio_cb = sub {
    my ($kernel, $dirs, $nondirs) = @_[KERNEL, ARG0, ARG1];
    my $filter = $self->has_filter ? $self->filter : undef;
    if( $self->has_dir_callback ){
      foreach my $child (@$dirs){
        $child = dir($self->directory, $child);
        next if ref $filter && !$filter->($child);
        $kernel->yield(dir_callback => $child);
      }
    }
    if( $self->has_file_callback ){
      foreach my $child (@$nondirs){
        $child = file($self->directory, $child);
        next if ref $filter && !$filter->($child);
        $poe_kernel->yield(file_callback => $child);
      }
    }
    $self->next_poll( $kernel->delay_set(poll => $self->interval) );
  };

  $_[KERNEL]->state(aio_callback => $aio_cb);
};

around _poll => sub {
  my $super = shift;
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  $self->clear_next_poll;
  my $dir = $self->directory->stringify;
  aio_scandir $dir, 0, $self->aio->postback('aio_callback');
};

before _shutdown => sub {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  $kernel->state('aio_callback');
  $self->aio->shutdown;
  $self->clear_aio;
};

1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------

=head1 NAME

POE::Component::DirWatch::Role::AIO - Make poll calls asynchronous

=head1 DESCRIPTION

POE::Component::DirWatch::Role::AIO adds support for non-blocking polling
operations using L<POE::Component::AIO> to interface with L<IO::AIO>. The
L<POE::Component::AIO> object is stored in the C<aio> attribute, so you can
access it in your own applications.

=head1 ATTRIBUTES

=head2 aio

A read-only instance of POE::Component::AIO that is automatically created
at instantiation time.

=head1 METHODS

=head2 start

C<after '_start'> Create the C<aio_callback> event and event handler.

=head2 _poll

C<around '_poll'> Replaces the original C<_poll> method with one that reads the
contents of the target directory asynchronously. The original sub is never
called.

=head1 SEE ALSO

L<POE::Component::DirWatch>, L<Moose>

=head1 COPYRIGHT

Copyright 2006-2008 Guillermo Roditi. This is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.

=cut

