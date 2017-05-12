package OpenGL::FTGL;
#
# Copyright (c) 2012 Jean-Louis Morel <jl_morel@bribes.org>
#
# Version 0.01 (25/06/2012)
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#

use 5.006000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

use constant FTGL_RENDER_FRONT => 0x0001;
use constant FTGL_RENDER_BACK  => 0x0002;
use constant FTGL_RENDER_SIDE  => 0x0004;
use constant FTGL_RENDER_ALL   => 0xffff;

use constant FTGL_ALIGN_LEFT    => 0;
use constant FTGL_ALIGN_CENTER  => 1;
use constant FTGL_ALIGN_RIGHT   => 2;
use constant FTGL_ALIGN_JUSTIFY => 3;

use constant FT_ENCODING_NONE      => 0;
use constant FT_ENCODING_MS_SYMBOL => unpack "N", 'symb';
use constant FT_ENCODING_UNICODE   => unpack "N", 'unic';

use constant FT_ENCODING_SJIS      => unpack "N", 'sjis';
use constant FT_ENCODING_GB2312    => unpack "N", 'gb  ';
use constant FT_ENCODING_BIG5      => unpack "N", 'big5';
use constant FT_ENCODING_WANSUNG   => unpack "N", 'wans';
use constant FT_ENCODING_JOHAB     => unpack "N", 'joha';

use constant FT_ENCODING_MS_SJIS    => FT_ENCODING_SJIS;
use constant FT_ENCODING_MS_GB2312  => FT_ENCODING_GB2312;
use constant FT_ENCODING_MS_BIG5    => FT_ENCODING_BIG5;
use constant FT_ENCODING_MS_WANSUNG => FT_ENCODING_WANSUNG;
use constant FT_ENCODING_MS_JOHAB   => FT_ENCODING_JOHAB;

use constant FT_ENCODING_ADOBE_STANDARD => unpack "N", 'ADOB';
use constant FT_ENCODING_ADOBE_EXPERT   => unpack "N", 'ADBE';
use constant FT_ENCODING_ADOBE_CUSTOM   => unpack "N", 'ADBC';
use constant FT_ENCODING_ADOBE_LATIN_1  => unpack "N", 'lat1';

use constant FT_ENCODING_OLD_LATIN_2    => unpack "N", 'lat2';

use constant FT_ENCODING_APPLE_ROMAN    => unpack "N", 'armn';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenGL::FTGL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
'all' => [ qw(
FTGL_RENDER_FRONT FTGL_RENDER_BACK FTGL_RENDER_SIDE FTGL_RENDER_ALL
FT_ENCODING_MS_SYMBOL
FT_ENCODING_NONE FT_ENCODING_MS_SYMBOL FT_ENCODING_UNICODE FT_ENCODING_SJIS
FT_ENCODING_GB2312 FT_ENCODING_BIG5 FT_ENCODING_WANSUNG FT_ENCODING_JOHAB
FT_ENCODING_MS_SJIS FT_ENCODING_MS_GB2312 FT_ENCODING_MS_BIG5 FT_ENCODING_MS_WANSUNG
FT_ENCODING_MS_JOHAB FT_ENCODING_ADOBE_STANDARD FT_ENCODING_ADOBE_EXPERT
FT_ENCODING_ADOBE_CUSTOM FT_ENCODING_ADOBE_LATIN_1 FT_ENCODING_OLD_LATIN_2
FT_ENCODING_APPLE_ROMAN
ftglCreateBitmapFont ftglCreateBufferFont
ftglCreateExtrudeFont ftglCreateOutlineFont ftglCreatePixmapFont
ftglCreatePolygonFont ftglCreateTextureFont ftglRenderFont ftglAttachData
ftglAttachFile ftglSetFontCharMap ftglGetFontCharMapList ftglSetFontFaceSize
ftglGetFontFaceSize ftglSetFontDepth ftglSetFontOutset ftglSetFontDisplayList
ftglGetFontAscender ftglGetFontDescender ftglGetFontLineHeight ftglGetFontBBox
ftglGetFontAdvance ftglGetFontError ftglGetFontErrorMsg ftglDestroyFont) ],
'FTGL_' => [ qw(
FTGL_RENDER_FRONT FTGL_RENDER_BACK FTGL_RENDER_SIDE FTGL_RENDER_ALL) ],
'FT_' => [ qw(
FT_ENCODING_MS_SYMBOL
FT_ENCODING_NONE FT_ENCODING_MS_SYMBOL FT_ENCODING_UNICODE FT_ENCODING_SJIS
FT_ENCODING_GB2312 FT_ENCODING_BIG5 FT_ENCODING_WANSUNG FT_ENCODING_JOHAB
FT_ENCODING_MS_SJIS FT_ENCODING_MS_GB2312 FT_ENCODING_MS_BIG5 FT_ENCODING_MS_WANSUNG
FT_ENCODING_MS_JOHAB FT_ENCODING_ADOBE_STANDARD FT_ENCODING_ADOBE_EXPERT
FT_ENCODING_ADOBE_CUSTOM FT_ENCODING_ADOBE_LATIN_1 FT_ENCODING_OLD_LATIN_2
FT_ENCODING_APPLE_ROMAN) ],

'ftgl' => [ qw(
ftglCreateBitmapFont ftglCreateBufferFont
ftglCreateExtrudeFont ftglCreateOutlineFont ftglCreatePixmapFont
ftglCreatePolygonFont ftglCreateTextureFont ftglRenderFont ftglAttachData
ftglAttachFile ftglSetFontCharMap ftglGetFontCharMapList ftglSetFontFaceSize
ftglGetFontFaceSize ftglSetFontDepth ftglSetFontOutset ftglSetFontDisplayList
ftglGetFontAscender ftglGetFontDescender ftglGetFontLineHeight ftglGetFontBBox
ftglGetFontAdvance ftglGetFontError ftglGetFontErrorMsg ftglDestroyFont) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('OpenGL::FTGL', $VERSION);

# Preloaded methods go here.

1;
__END__


=head1 NAME

OpenGL::FTGL - interface to the FTGL library (to use arbitrary fonts in OpenGL applications).


=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use OpenGL ':all';
  use OpenGL::FTGL ':all';

  my $font = ftglCreateOutlineFont("/path_to/Arial.ttf")
    or die $!;
  ftglSetFontFaceSize($font, 72);

  sub display {
    glClear(GL_COLOR_BUFFER_BIT);    # clear window
    glPushMatrix();
      glTranslatef(50, 80, 0);       # translate...
      glRotatef(20, 0, 0, 1);        # and rotate the text
      ftglRenderFont($font, "Hello World!");
    glPopMatrix();
    glFlush();
  }

  glutInit();
  glutInitWindowSize(600, 300);           # 600 x 300 pixel window
  glutCreateWindow("Hello OpenGL::FTGL"); # window title
  glutDisplayFunc(\&display);  # callback invoked when window opened

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluOrtho2D(0, 600, 0, 300);
  glMatrixMode(GL_MODELVIEW);

  glutMainLoop();              # enter event loop

=head1 DESCRIPTION

OpenGL doesn't provide direct font support. FTGL is a free, open
source library which makes possible to use TrueType or OpenType fonts
in an OpenGL application.

=head2 FUNCTIONS

The seven C<ftglCreate*> functions take as parameter C<$fontfile> which is
the path to a font file.
The supported formats are those of the FreeType2 library:

  - TrueType fonts (and collections)
  - Type 1 fonts
  - CID-keyed Type 1 fonts
  - CFF fonts
  - OpenType fonts (both TrueType and CFF variants)
  - SFNT-based bitmap fonts
  - X11 PCF fonts
  - Windows FNT fonts
  - BDF fonts (including anti-aliased ones)
  - PFR fonts
  - Type 42 fonts (limited support)

These functions return an FTGL C<$font> object or C<undef> if an error occurs.

If the variable C<$font> goes out of scope or receives another value, the
font is automatically destroyed. Don't worry yourself about the C<ftglDestroyFont>
function.

=over

=item * $font = ftglCreateBitmapFont( $fontfile );

Bitmap fonts use 1-bit (2-colour) rasterised glyphs.
A bitmap font cannot be directly rotated or scaled.

=item * $font = ftglCreatePixmapFont( $fontfile );

Pixmap fonts use 8-bit (256 levels) rasterised glyphs.
A pixmap font cannot be directly rotated or scaled.

=item * $font = ftglCreateOutlineFont( $fontfile );

Outline fonts use OpenGL lines.

=item * $font = ftglCreatePolygonFont( $fontfile );

Polygon fonts use planar triangle meshes and can be texture-mapped.

=item * $font = ftglCreateExtrudeFont( $fontfile );

Extruded fonts are extruded polygon fonts, with the front, back and
side meshes renderable separately to apply different effects and materials.

=item * $font = ftglCreateTextureFont( $fontfile );

Texture fonts use one texture per glyph. They are fast because glyphs are
stored permanently in the video card's memory

=item * $font = ftglCreateBufferFont( $fontfile );

Buffer fonts use one texture per line of text. They tend to be faster
than texture fonts when the same line of text needs to be rendered
for more than one frame.

=item * ftglRenderFont ( $font, $string [, $mode] );

Render a C<$string> of characters with C<$font>.
The optional render C<$mode> is an ORed-together combination of

  FTGL_RENDER_FRONT
  FTGL_RENDER_BACK
  FTGL_RENDER_SIDE
  FTGL_RENDER_ALL    ( = FTGL_RENDER_FRONT | FTGL_RENDER_BACK | FTGL_RENDER_SIDE )

Default value for C<$mode> is C<FTGL_RENDER_ALL>.

=item * $success = ftglSetFontCharMap ( $font, $encoding );

Set the character map for the C<$font>.
C<$encoding> is one of the FreeType char map code:

  FT_ENCODING_NONE          FT_ENCODING_MS_SYMBOL       FT_ENCODING_UNICODE
  FT_ENCODING_SJIS          FT_ENCODING_GB2312          FT_ENCODING_BIG5
  FT_ENCODING_WANSUNG       FT_ENCODING_JOHAB           FT_ENCODING_MS_SJIS
  FT_ENCODING_MS_GB2312     FT_ENCODING_MS_BIG5         FT_ENCODING_MS_WANSUNG
  FT_ENCODING_MS_JOHAB      FT_ENCODING_ADOBE_STANDARD  FT_ENCODING_ADOBE_EXPERT
  FT_ENCODING_ADOBE_CUSTOM  FT_ENCODING_ADOBE_LATIN_1   FT_ENCODING_OLD_LATIN_2
  FT_ENCODING_APPLE_ROMAN

Return 1 if C<$encoding> was valid and set correctly.

By default, when a new face object is created, (FreeType) lists all the charmaps
contained in the font face and selects the one that supports Unicode character
codes if it finds one. Otherwise, it tries to find support for Latin-1, then ASCII.

It then gives up. In this case FTGL will set the charmap to the first it finds
in the fonts charmap list. You can explicitly set the char encoding with
C<ftglSetFontCharMap>.

=item * @list = ftglGetFontCharMapList ( $font );

Return the list of character maps in the C<$font>.

=item * $success = ftglSetFontFaceSize ( $font, $size [, $resolution] );

Set the character size of C<$font> to the C<$size> in point (1/72 inc).
The optional parameter C<$resolution> set the resolution of the target
device (default value of 72 if omited).

Return 1 if C<$size> was set correctly.

=item * ftglSetFontDepth ( $font, $depth );

Set the extrusion distance C<$depth> for the C<$font>.

Only implemented if C<$font> is an C<ExtrudeFont>.

=item * ftglSetFontOutset ( $font, $front, $back );

Set the outset distance for the C<$font>.

Only C<OutlineFont>, C<PolygoneFont> and C<ExtrudeFont> implement C<$front> outset.

Only C<ExtrudeFont> implement C<$back> outset.

=item * ftglSetFontDisplayList ( $font, $useList);

Enable or disable the use of Display Lists inside FTGL for the C<$font>.

Set C<$useList> to 1 turns ON display lists. 0 turns OFF display lists.

=item * $size = ftglGetFontFaceSize ( $font );

Get the C<$font> size in point (1/72 inch).

=item * $advance = ftglGetFontAdvance ( $font, $string );

Get the advance width for C<$string> using C<$font>.

=item * $ascender = ftglGetFontAscender ( $font );

Get the global ascender height for the C<$font>.

=item * $descender = ftglGetFontDescender ( $font );

Get the global descender height for the C<$font>.

=item * $height = ftglGetFontLineHeight ( $font );

Get the line spacing for the C<$font>.

=item * @boundingbox = ftglGetFontBBox ( $font, $sting [, $len] );

Get the bounding box for the C<$string> using the C<$font>.

If present, the optional parameter C<$len> specifies the number of character
of C<$string> to be checked.

The function return the bounding box's lower left near and upper right far 3D
coordinates.

=item * $errornumber = ftglGetFontError ( $font );

Query a C<$font> for errors. Return the current error code.

=item * $errornumber = ftglGetFontErrorMsg ( $font );

Query a C<$font> for errors. Return the current error message.

=back

=head2 EXPORT

Nothing by default;
the function names and constants must be explicitly exported.

=head2 Export Tags:

=over

=item * :ftgl

exports all the C<ftgl*> functions.

=item * :FTGL_

exports the C<FTGL_> constants

=item * :FT_

exports C<FT_ENCODING> constants

=item * :all

exports all.

=back


=head1 SEE ALSO

The FTGL library home page:

  http://ftgl.sourceforge.net/docs/html/index.html

The FreeType 2 home page:

  http://www.freetype.org/freetype2/

=head1 AUTHOR

J-L Morel E<lt>jl_morel@bribes.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by J-L Morel. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
