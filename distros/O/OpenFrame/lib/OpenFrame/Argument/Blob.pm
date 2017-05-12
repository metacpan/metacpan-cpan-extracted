package OpenFrame::Argument::Blob;

use strict;
use warnings::register;

use IO::Null;
use OpenFrame::Object;
use base qw ( OpenFrame::Object );

our $VERSION=3.05;

sub init {
  my $self = shift;

  $self->name( '' );                     ## initialize the argument name
  $self->filename( '' );                 ## initialize the filename
  $self->filehandle( IO::Null->new() );  ## initialize the filehandle

  $self->SUPER::init(@_);
}

sub name {
  my $self = shift;
  my $name = shift;
  if (defined($name)) {
    $self->{name} = $name;
    return $self;
  } else {
    return $self->{name};
  }
}

sub filename {
  my $self = shift;
  my $file = shift;
  if (defined($file)) {
    $self->{filename} = $file;
    return $self;
  } else {
    return $self->{filename};
  }
}

sub filehandle {
  my $self = shift;
  my $fh   = shift;
  if (defined($fh)) {
    $self->{filehandle} = $fh;
    return $self;
  } else {
    return $self->{filehandle};
  }
}

sub STORABLE_freeze {
  my $self = shift;
  $self->filehandle('');
}

sub STORABLE_thaw {

}

1;

=head1 NAME

OpenFrame::Argument::Blob - handling for filehandle-style data in network requests

=head1 SYNOPSIS

  use OpenFrame::Argument::Blob;

  my $blob = OpenFrame::Argument::Blob->new();

  $blob->filename( 'somefilename.dat' );
  $blob->filehandle( $fh );

  my $filename   = $blob->filename; 
  my $filehandle = $blob->filehandle;

=head1 DESCRIPTION

C<OpenFrame::Argument::Blob> is a class to support things such as browser-based uploads.  It provides
a mechanisms to get the filehandle and filename of the uploaded element.  

=head1 METHODS

=over 4

=item filename( [ SCALAR ] )

The C<filename()> method gets/sets the value of the filename attribute of the class.  This should return
the filename of the uploaded data.

=item filehandle( [ IO::Handle ] )

The C<filehandle> method gets/sets the value of the filehandle that points to the uploaded data.

=back

=head1 INHERITANCE

C<OpenFrame::Argument::Blob> inherits from the C<OpenFrame::Object> class and provides all methods that
its super class does.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved.

This code is released under the GNU GPL and Artistic licenses.

=cut



