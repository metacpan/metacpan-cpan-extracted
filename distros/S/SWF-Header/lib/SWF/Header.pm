package SWF::Header;

use strict;
use vars qw($VERSION);
$VERSION = '0.04';

use SWF::BinStream;
use Carp;

=head1 NAME

SWF::Header - extract header information from SWF files.

=head1 SYNOPSIS

  use SWF::Header;
  my $header_data = SWF::Header->read_file('/path/to/file.swf');
  
  or
  
  my $header_data = SWF::Header->read_data($binary_data);
  
  or
  
  my $h = SWF::Header->new();
  my %headers = map { $_ => $h->read_file($_) } @files;
  

=head1 DESCRIPTION

I<SWF::Header> pulls the descriptive information out of the header of a shockwave (.swf) file. It returns a hashref of height, width, duration, framerate, shockwave version and file size.

=head2 METHODS

=over 4

=item new()

Creates a reader object. You don't normally need to call the constructor directly unless you want to read several files. Either read_file or read_data will construct an object to do the work if called as a class method.

=cut

sub new {
    my $class = shift;
    my $self = { 
        _version => 5,
        _stream => undef,
	};
    return bless $self, $class;
}

=item stream( $stream )

A set or get method that can be used to provide an SWF::BinStream::Read object you want to work with. If none is supplied or exists already, calls new_stream to create a new one.

=cut

sub stream {
    my ($self, $s) = @_;
    return $self->{_stream} = $s if $s;
    return $self->{_stream} if $self->{_stream};
    return $self->new_stream;
}

=item new_stream()

Resets the reader's stream to a new SWF::BinStream::Read object, ready to start from scratch. Both read_file and read_data call this method before handing over to parse_header.

=cut

sub new_stream {
    my ($self, $data) = @_;
    return $self->{_stream} = SWF::BinStream::Read->new($data, sub{ Carp::croak("The stream ran short by $_[0] bytes.") });    
}

=item read_file( $file )

Opens and reads the first few bytes of the file supplied (as either a filehandle or a path), uses them to start a new stream then calls parse_header.

=cut

sub read_file {
    my ($self, $path) = @_;
    return unless $path;
    my $file;
    if (ref($path)) {
        $file = $path;
    } else {
	    open( $file, $path ) or Carp::croak(1, "opening $path failed: $!");
    }
    binmode($file);
    read($file, my $data, 4096);

    $self = $self->new() unless ref $self;
    $self->new_stream($data);
    return $self->parse_header;
}

=item read_data( $string )

Just for consistency. All this does is start a new stream with the data supplied and call parse_header.

=cut

sub read_data {
    my ($self, $data) = @_;
    return unless $data;

    $self = $self->new() unless ref $self;
    $self->new_stream($data);
    return $self->parse_header;
}

=item parse_header( $string )

Checks that this is a properly-formatted SWF file, then pulls the relevant bytes out of the header block of the file and returns a hashref containing the stage dimensions, coordinates, duration, frame rate, version and file size. In detail:

  {
    signature => 'FWS' or 'CWS',
    version => Shockwave language version,
    filelen => Length of entire file in bytes,
    xmin => Stage left edge, in twips,
    xmax => Stage right edge, in twips from left,
    ymin => Stage top edge,
    ymax => Stage bottom edge, in twips from top,
    rate => Frame rate in fps,
    count => total number of frames in movie,
    width => calculated width of stage (in pixels),
    height => calculated height of stage (in pixels),
    duration => calculated duration of movie (in seconds),
    background => calculated background color of movie (in html format),
  }
  
=cut

sub parse_header {
    my ($self, $data) = @_;
    $self->stream->add_stream($data) if $data;

    my $header = {};
    $header->{signature} = $self->stream->get_string(3);
    if ($header->{signature} ne 'CWS' && $header->{signature} ne 'FWS') {
        Carp::carp "This is not an SWF stream ";
        return;
    }
    $header->{version} = $self->{_version} = $self->stream->get_UI8;
    $header->{filelen} = $self->stream->get_UI32;
    $self->stream->add_codec('Zlib') if $header->{signature} eq 'CWS';

    my $nbits = $self->stream->get_bits(5);
    $header->{xmin} = $self->stream->get_sbits($nbits);
    $header->{xmax} = $self->stream->get_sbits($nbits);
    $header->{ymin} = $self->stream->get_sbits($nbits);
    $header->{ymax} = $self->stream->get_sbits($nbits);
    $header->{rate} = $self->stream->get_UI16 / 256;
    $header->{count} = $self->stream->get_UI16;
    $header->{width} = int(($header->{xmax} - $header->{xmin}) / 20);
    $header->{height} = int(($header->{ymax} - $header->{ymin}) / 20);
    $header->{duration} = $header->{count} / $header->{rate};

    my $temp = $self->stream->get_sbits($nbits);
    my $background_r = $self->stream->get_UI8();
    my $background_g = $self->stream->get_UI8();
    my $background_b = $self->stream->get_UI8();
    $header->{background} = sprintf ("#%02X%02X%02X", $background_r, $background_g, $background_b);

    return $header;
}

=head1 COPYRIGHT

Copyright 2004 William Ross (wross@cpan.org)

But obviously based entirely on previous work by Yasuhiro Sasama.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<SWF::File>, L<SWF::Parser>, L<SWF::BinStream>, L<SWF::Element>

The SWF file format specification from Macromedia can be found at 
http://www.openswf.org/spec/SWFfileformat.html

=cut

1;
