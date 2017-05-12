use 5.006;
use strict;
use warnings;

package Pod::Eventual::Reconstruct;

# ABSTRACT: Construct a document from Pod::Eventual events

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY












use Moo 1.000008 qw( has );    # builder => CODE
use Path::Tiny qw(path);
use autodie qw(open close);
use Carp qw( croak );





has write_handle => ( is => ro =>, required => 1 );

no Moo;











## no critic (RequireArgUnpacking,RequireBriefOpen)
sub string_writer {
  my $class = $_[0];
  my $string_write;

  if ( not ref $_[1] ) {
    $string_write = \$_[1];
  }
  elsif ( ref $_[1] ne 'SCALAR' ) {
    croak '->string_writer( string ) must be a scalar or scalar ref';
  }
  else {
    $string_write = $_[1];
  }
  open my $fh, '>', $string_write;
  return $class->handle_writer( $fh, $_[2] );
}
## use critic











sub file_writer {
  my ( $class, $file, $mode ) = @_;
  return $class->handle_writer( path($file)->openw($mode) );
}











sub file_writer_raw {
  my ( $class, $file ) = @_;
  return $class->handle_writer( path($file)->openw_raw() );
}











sub file_writer_utf8 {
  my ( $class, $file ) = @_;
  return $class->handle_writer( path($file)->openw_utf8() );
}









sub handle_writer {
  my ( $class, $handle ) = @_;
  return $class->new( write_handle => $handle );
}













sub write_event {
  my ( $self, $event ) = @_;
  my $writer = 'write_' . $event->{type};
  if ( not $self->can($writer) ) {
    croak( 'no writer for event type ' . $event->{type} );
  }
  return $self->$writer($event);
}











sub write_command {
  my ( $self, $event ) = @_;
  if ( $event->{type} ne 'command' ) {
    croak('write_command cant write anything but nonpod');
  }
  my $content = $event->{content};
  if ( $content !~ qr{ \A \s+ \z }sx ) {
    $content = q[ ] . $content;
  }
  $self->write_handle->printf( q{=%s%s}, $event->{command}, $content );

  #if ( $event->{command} ne 'cut' ){
  #    $self->write_handle->printf(qq{\n});
  #}
  return $self;
}











sub write_text {
  my ( $self, $event ) = @_;
  if ( $event->{type} ne 'text' ) {
    croak('write_text cant write anything but text');
  }
  $self->write_handle->print( $event->{content} );
  return $self;
}











sub write_nonpod {
  my ( $self, $event ) = @_;
  if ( $event->{type} ne 'nonpod' ) {
    croak('write_nonpod cant write anything but nonpod');
  }
  $self->write_handle->print( $event->{content} );
  return $self;

}











sub write_blank {
  my ( $self, $event ) = @_;
  if ( $event->{type} ne 'blank' ) {
    croak('write_blank cant write anything but blanks');
  }
  $self->write_handle->print( $event->{content} );
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Eventual::Reconstruct - Construct a document from Pod::Eventual events

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

Constructing a Document from a series of Pod::Eventual events is not hard, its just slightly nuanced,
and there's a few small pitfalls for people who want input == output consistency.

This module simply implements the basic layers of edge-cases to make that simpler.

=head2 Construct the reconstructor

    # Write to $string
    my $string;
    my $recon = Pod::Eventual::Reconstruct->string_writer( $string )
    # or
    my $recon = Pod::Eventual::Reconstruct->string_writer( \$string )
    # ( both work )

    # Write to $file
    my $recon = Pod::Eventual::Reconstruct->file_writer( $file )

    # Write to file in utf8 mode
    my $recon = Pod::Eventual::Reconstruct->file_writer_utf8( $file )

    # Write to filehandle
    my $recon = Pod::Eventual::Reconstruct->handle_writer_utf8( $handle )

=head2 Send Events to it

    $recon->write_event( $hashref_from_pod_elemental )

=head1 METHODS

=head2 string_writer

Create a reconstructor that writes to a string

    my $reconstructor = ::Reconstruct->string_writer( $string )
    my $reconstructor = ::Reconstruct->string_writer( \$string )

=head2 file_writer

Create a reconstructor that writes to a file

    my $reconstructor = ::Reconstruct->file_writer( $file_name )

Values of C<Path::Tiny> or C<Path::Class> should also work as values of C<$file_name>

=head2 file_writer_raw

Create a reconstructor that writes to a file in raw mode

    my $reconstructor = ::Reconstruct->file_writer_raw( $file_name )

Values of C<Path::Tiny> or C<Path::Class> should also work as values of C<$file_name>

=head2 file_writer_utf8

Create a reconstructor that writes to a file in C<utf8> mode

    my $reconstructor = ::Reconstruct->file_writer_utf8( $file_name )

Values of C<Path::Tiny> or C<Path::Class> should also work as values of C<$file_name>

=head2 handle_writer

Create a reconstructor that writes to a file handle

    my $reconstructor = ::Reconstruct->handle_writer( $handle )

=head2 write_event

Write a L<< C<Pod::Eventual>|Pod::Eventual >> event of any kind to the output target.

    $recon->write_event( $eventhash );

Note: This is just a proxy for the other methods which delegates based on the value of C<< $eventhash->{type} >>.

Unknown C<type>'s will cause errors.

=head2 write_command

Write a  L<< C<Pod::Eventual>|Pod::Eventual >> C<command> event.

C<< $event->{type} >> B<MUST> be C<eq 'command'>

    $recon->write_command({ type => 'command', ... });

=head2 write_text

Write a  L<< C<Pod::Eventual>|Pod::Eventual >> C<text> event.

C<< $event->{type} >> B<MUST> be C<eq 'text'>

    $recon->write_text({ type => 'text', ... });

=head2 write_nonpod

Write a  L<< C<Pod::Eventual>|Pod::Eventual >> C<nonpod> event.

C<< $event->{type} >> B<MUST> be C<eq 'nonpod'>

    $recon->write_nonpod({ type => 'nonpod', ... });

=head2 write_blank

Write a  L<< C<Pod::Eventual>|Pod::Eventual >> C<blank> event.

C<< $event->{type} >> B<MUST> be C<eq 'blank'>

    $recon->write_blank({ type => 'blank', ... });

=head1 ATTRIBUTES

=head2 write_handle

=begin MetaPOD::JSON v1.0.0

{
    "namespace":"Pod::Eventual::Reconstruct",
    "inherits": "Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
