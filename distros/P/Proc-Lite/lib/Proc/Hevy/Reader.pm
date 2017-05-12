package Proc::Hevy::Reader;

use strict;
use warnings;

use Carp;
use Errno qw( EWOULDBLOCK );
use IO::Pipe;
use POSIX ();


sub new {
  my ( $class, $name, $buffer ) = @_;

  my $pipe;
  $pipe = IO::Pipe->new
    if defined $buffer and ref $buffer ne 'GLOB';

  bless { name => $name, buffer => $buffer, pipe => $pipe }, $class;
}

sub child {
  my ( $self, $std_h, $fileno ) = @_;

  my $handle;

  if( defined $self->{pipe} ) {
    $handle = $self->{pipe}->writer;
  }
  elsif( ref $self->{buffer} eq 'GLOB' ) {
    $handle = $self->{buffer};
  }
  else {
    open $handle, '>', '/dev/null'
      or confess "$self->{name}: open: /dev/null: $!\n";
  }

  $handle->autoflush;

  POSIX::dup2( $handle->fileno, $fileno )
    or confess "$self->{name}: dup2: $!\n"
      if $std_h != $handle;
}

sub parent {
  my ( $self, $select ) = @_;

  unless( defined $self->{pipe} ) {
    delete $self->{buffer}
      if defined $self->{buffer};

    return;
  }

  $self->{scratch} = undef;

  my $handle = $self->{pipe}->reader;
  $handle->blocking( 0 );

  $select->add( $handle );
  $self->{select} = $select;

  return ( $handle, $self );
}

sub read {
  my ( $self ) = @_;

  my $handle = $self->{pipe};
  my $rc     = $handle->sysread( my $data, 4096 );

  if( not defined $rc ) {
    if( $! != EWOULDBLOCK ) {
      $self->_flush( $self->{scratch} );
      confess "$self->{name}: sysread: $!\n";
    }
  }
  elsif( $rc == 0 ) {
    $self->_flush( $self->{scratch} );

    $self->{select}->remove( $handle );
    $handle->close
      or confess "$self->{name}: close: $!\n";
  }
  else {
    $self->_pack( $data );
  }
}

sub _pack {
  my ( $self, $data ) = @_;

  if( ref $self->{buffer} eq 'SCALAR' ) {
    ${ $self->{buffer} } .= $data;
  }
  else {
    my $scratch = ( defined $self->{scratch} ? $self->{scratch} : '' ) . $data;

    if( defined $/ ) {
      while( index( $scratch, $/ ) != -1 ) {
        ( my $line, $scratch ) = split m#$/#, $scratch, 2;
        $self->_flush( $line );
      }
    }

    $self->{scratch} = length $scratch ? $scratch : undef;
  }
}

sub _flush {
  my ( $self, $data ) = @_;

  return
    unless defined $data;

  my $buffer = $self->{buffer};

  if( ref $buffer eq 'ARRAY' ) {
    push @$buffer, $data;
  }
  elsif( ref $buffer eq 'CODE' ) {
    $buffer->( $data );
  }
  else {
    confess "$self->{name}: API error\n";
  }
}


1
__END__

=pod

=head1 NAME

Proc::Hevy::Reader - A reader pipe implementation for Proc::Hevy

=head1 DESCRIPTION

Proc::Heavy::Reader implements a reader pipe that reads
data from a child process handle to a provided buffer.  This is
used when capturing C<STDOUT> and C<STDERR> data from a child process.

=head1 INTERFACE

=head2 new( $name, $buffer )

Creates a new C<Proc::Hevy::Reader> object.  C<$name> is a
symbolic name for the reader.  C<$buffer> is the storage mechanism
to be used for data read from the child process.  It can either
be a simple scalar, an C<ARRAY> reference, a C<CODE> reference or a
C<GLOB> reference.

=head2 child( $handle )

Performs actions suitable when running as part of the child process.
This includes re-opening the provided C<$handle> to a filehandle
that is created based on the type of storage buffer configured
in C<new()>.  If no buffer was configured, C<'/dev/null'> is
opened for writing.

=head2 parent( $select )

Performs actions suitable when running as part of the parent process.
This includes adding filehandles to the provided C<$select> object
that should be monitored for readability.

=head2 read

Performs the actual read from the child process and stores any
read data into the storage buffer configured in C<new()>.  At
EOF, applicable filehandles are closed and removed from the
select object used in the call to C<parent()>.  Any system
errors are considered fatal.

=head1 BUGS

None are known at this time, but if you find one, please feel free
to submit a report to the author.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Proc::Hevy>

=back

=head1 COPYRIGHT

Copyright (c) 2009-2014, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
