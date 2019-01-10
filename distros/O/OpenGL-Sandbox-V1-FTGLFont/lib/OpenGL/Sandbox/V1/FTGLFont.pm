package OpenGL::Sandbox::V1::FTGLFont;
use Moo;
use Cwd;
use OpenGL::Sandbox::V1 0.04;
use OpenGL::Sandbox::MMap;

# ABSTRACT: Wrapper object for FTGL Fonts
BEGIN {
our $VERSION = '0.042'; # VERSION
}


has filename => ( is => 'ro' );
has type => ( is => 'ro', required => 1, default => sub { 'FTTextureFont' } );
has data => ( is => 'ro', required => 1 );
has _ftgl_wrapper => ( is => 'lazy', handles => [qw(
	face_size
	ascender
	descender
	line_height
	advance
)]);


sub BUILD {
	my ($self, $args)= @_;
	# Apply face size if given, else default
	$self->face_size($args->{face_size} || 24);
}

sub _build__ftgl_wrapper {
	my $self= shift;
	my $class= __PACKAGE__.'::FTFontWrapper';
	$class->new($self->data, $self->type);
}

our %h_align_map= ( left => 1, center => 2, right => 3 );
our %v_align_map= ( top => 4, center => 3, base => 2, bottom => 1 );


sub render {
	my $self= shift;
	if (@_ == 2 && ref $_[1] eq 'HASH') {
		my $opts= pop;
		push @_, %$opts;
	}
	unshift @_, $self->_ftgl_wrapper;
	goto $_[0]->can('render');
}

use OpenGL::Sandbox::V1::FTGLFont::Inline
	CPP => do { my $x= __FILE__; $x =~ s/\.pm$/\.cpp/; $x },
	INC => '-I/usr/include/FTGL -I/usr/include/freetype2 -I'
	       .do{ my $x= __FILE__; $x =~ s|/[^/]+$||; Cwd::abs_path($x) },
	LIBS => '-lfreetype -lftgl';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::V1::FTGLFont - Wrapper object for FTGL Fonts

=head1 VERSION

version 0.042

=head1 DESCRIPTION

L<FTGL|http://ftgl.sourceforge.net/docs/html/> is a C++ library that uses the FreeType library
to read font glyphs and encodes them as OpenGL textures or vertex geometry.
It then handles all the details of rendering a string of text with correct font spacing.

The library has a spectacularly designed API, and supports unicode, and other great things.
Unfortunately, it is very tied to the OpenGL 1.x API, which is deprecated.
If you are working on something simple and the 1.x API works for you, then this will solve your
font needs and you can go merrily on your way.

This module is based on L<Inline::CPP>, so it requires a C++ compiler in order to be installed.

=head1 ATTRIBUTES

=head2 type

The C++ font class to use.  FTGL implements fonts in several different ways, such as
texture-of-glyphs, texture-of-string, 3D model, 2D model, etc.  These are represented by
various C++ classes.  The module Inline::CPP cannot currently parse the external class
definitions of FTGL, so each FTGL class must be wrapped by code in the C++ portion of this
module.

Currently must be one of C<'FTTextureFont'>, C<'FTExtrudeFont'>, C<'FTPolygonFont'>,
C<'FTPixmapFont'>, C<'FTOutlineFont'>, C<'FTBufferFont'>, or C<'FTBitmapFont'>.

=head2 data

A scalar-ref to the bytes of a TrueType font, preferably via a L</OpenGL::Sandbox::MMap>
object.

=head2 filename

The name this data was loaded from, for informational purposes only.

=head2 face_size

When using textured fonts, this is roughly the pixel/texel size of the glyphs that will be
rendered into the texture.  When using geometric fonts (i.e. polygon-based) this will be the
OpenGL coordinate space scale of the font.

=head2 ascender

The distance from baseline to top of typical glyph, in same units as face_size.

=head2 descender

The distance below the baseline that "hanging" portions of glyphs might reach, in same units
as face_size.

=head2 line_height

Line spacing for the font, in same units as face_size.

=head1 METHODS

=head2 advance

  my $length= $font->advance("String of glyphs");

Calculate the width of a sting of text, in same units as face_size.

=head2 render

  $font->render($text, %opts);

Render some text using this font.  By default, it renders with the baseline starting at the
OpenGL origin.  To save some awkward math, the following options are supported:

=over

=item C<x>, C<y>

Use this reference coordinate instead of the OpenGL origin.

=item C<xalign>

A number between C<0> (left align) and C<1> (right align).  i.e. to center the text use C<0.5>.

=item C<yalign>

C<0> puts the baseline at the y coordinate.  C<1> puts the ascender-line at the y coordinate.
C<-1> puts the descender-line at the y coordinate.  Numbers inbetween yield some fraction
of those distances.

In other words,

   1   = 'top'
   0.5 = 'center'
   0   = 'baseline'
  -1   = 'bottom'

=item C<monospace>

Ignore the spacing of the font face and always use this value to advance between glyphs.
This number is in the same units as font_face.  This value is affected by C<scale> (below).

=item C<scale>

Scale the x and y axis by this number before rendering.  (but restores the OpenGL matrix before
returning).  This overrides a setting of C<height>.

=item C<h>, C<height>

Scale the y axis so that the L</ascender> equals this value.  Also scale the x axis to match
unless C<scale> or C<height> were specified, in which case this can change the aspect ratio of
the text.

=item C<w>, C<width>

Scale x axis so that the length of the text is C<width>.  Also scale the y axis to match unless
C<scale> or C<height> were specified, in which case this can change the aspect ratio of the text.

=back

Note: If this is a TextureFont, it will change the current bound texture.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
