package PDF::Make::Font;
use strict;
use warnings;

our $VERSION = '0.15';

# Load the XS via PDF::Make
require PDF::Make;

# Font types
use constant {
    TYPE_TYPE1     => 0,
    TYPE_TRUETYPE  => 1,
    TYPE_CID_TRUETYPE => 2,
};

# Standard 14 font names
our @STD14_NAMES = qw(
    Helvetica
    Helvetica-Bold
    Helvetica-Oblique
    Helvetica-BoldOblique
    Times-Roman
    Times-Bold
    Times-Italic
    Times-BoldItalic
    Courier
    Courier-Bold
    Courier-Oblique
    Courier-BoldOblique
    Symbol
    ZapfDingbats
);

sub new {
    my ($class, %opts) = @_;
    
    if (my $file = $opts{file}) {
        return $class->from_file($file, $opts{arena});
    }
    elsif (my $bytes = $opts{bytes}) {
        return $class->from_bytes($bytes, $opts{arena});
    }
    elsif (my $std14 = $opts{standard14} // $opts{std14}) {
        return $class->standard14($std14, $opts{arena});
    }
    else {
        require Carp;
        Carp::croak("PDF::Make::Font: must specify file, bytes, or standard14");
    }
}

sub is_standard14 {
    my $self = shift;
    return $self->type == TYPE_TYPE1;
}

sub is_truetype {
    my $self = shift;
    return $self->type == TYPE_TRUETYPE || $self->type == TYPE_CID_TRUETYPE;
}

1;

__END__

=head1 NAME

PDF::Make::Font - Font handling for PDF generation

=head1 SYNOPSIS

    use PDF::Make::Font;
    
    # Create a Standard 14 font
    my $font = PDF::Make::Font->standard14('Helvetica');
    
    # Or load a TrueType font
    my $font = PDF::Make::Font->from_file('/path/to/font.ttf');
    
    # Get text width
    my $width = $font->string_width("Hello World", 12);
    
    # Get individual glyph advance
    my $advance = $font->advance(ord('A'), 12);
    
    # Get font metrics
    my $metrics = $font->metrics;
    print "Ascent: $metrics->{ascent}\n";

=head1 DESCRIPTION

PDF::Make::Font provides font handling for PDF generation, supporting:

=over 4

=item * Standard 14 fonts (built into all PDF readers)

=item * TrueType font embedding with subsetting

=item * Font metrics and glyph widths

=item * UTF-8 text encoding

=back

=head1 CONSTRUCTORS

=head2 standard14($base_font, $arena?)

Create a Standard 14 font by name. Valid names are:

    Helvetica, Helvetica-Bold, Helvetica-Oblique, Helvetica-BoldOblique
    Times-Roman, Times-Bold, Times-Italic, Times-BoldItalic
    Courier, Courier-Bold, Courier-Oblique, Courier-BoldOblique
    Symbol, ZapfDingbats

=head2 from_file($path, $arena?)

Load a TrueType font from a file.

=head2 from_bytes($bytes, $arena?)

Load a TrueType font from bytes in memory.

=head2 new(%opts)

General constructor. Options:

    file      => '/path/to/font.ttf'
    bytes     => $ttf_bytes
    standard14 => 'Helvetica'  # or std14
    arena     => $arena  # optional

=head1 METHODS

=head2 base_font()

Returns the PostScript font name (e.g., "Helvetica", "ArialMT").

=head2 type()

Returns the font type constant (TYPE_TYPE1, TYPE_TRUETYPE, TYPE_CID_TRUETYPE).

=head2 is_standard14()

Returns true if this is a Standard 14 font.

=head2 is_truetype()

Returns true if this is a TrueType font.

=head2 std14_id()

For Standard 14 fonts, returns the font ID constant.

=head2 advance($codepoint, $font_size)

Returns the advance width for a single Unicode codepoint at the given font size.

=head2 string_width($utf8_string, $font_size)

Returns the total width of a UTF-8 string at the given font size.

=head2 metrics()

Returns a hashref of font metrics:

    {
        ascent       => 718,    # Ascender height (units/1000 em)
        descent      => -207,   # Descender (negative)
        cap_height   => 718,    # Capital letter height
        x_height     => 523,    # Lowercase x height
        stem_v       => 88,     # Vertical stem width
        stem_h       => 76,     # Horizontal stem width
        italic_angle => 0,      # Italic angle (degrees)
        flags        => 32,     # Font flags
        bbox         => [-166, -225, 1000, 931],  # Bounding box
    }

=head2 encode_utf8($utf8_string)

Encodes a UTF-8 string to PDF string bytes. For Standard 14 fonts, this
produces WinAnsi encoding. For TrueType fonts, this produces CID encoding.
Also marks used glyphs for later subsetting.

=head2 write_to_doc($doc)

Writes the font to a PDF document and returns the object number.

A Standard 14 font becomes a simple C</Type1> dictionary. A TrueType font is
subsetted to the glyphs marked used - which is what C<encode_utf8> marks as it
encodes - and written as a C</Type0> font with C<Identity-H> encoding over a
C</CIDFontType2> descendant, with the font program in C</FontFile2>, a
C</CIDToGIDMap> stream and a C</ToUnicode> CMap.

Call it after the content streams that use the font are built, or the subset
will not contain their glyphs. Writing the same font twice returns the same
object number rather than embedding it again.

The object number is not attached to any page by itself: pass it to
C<< PDF::Make::Page->add_font_ref >> to make it usable from a content stream.

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Font::Std14>

=cut
