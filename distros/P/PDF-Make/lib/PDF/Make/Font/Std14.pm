package PDF::Make::Font::Std14;
use strict;
use warnings;

our $VERSION = '0.02';

# Load the XS via PDF::Make
require PDF::Make;

# Re-export constants from XS
# These are defined in font.xs

1;

__END__

=head1 NAME

PDF::Make::Font::Std14 - Standard 14 font constants and utilities

=head1 SYNOPSIS

    use PDF::Make::Font::Std14;
    
    # Get font ID constant
    my $id = PDF::Make::Font::Std14->HELVETICA;
    
    # Look up font by name
    my $id = PDF::Make::Font::Std14->lookup('Times-Roman');
    
    # Get glyph width
    my $width = PDF::Make::Font::Std14->width($id, ord('A'));

=head1 DESCRIPTION

This module provides constants and utility functions for the 14 Standard
fonts that are built into every PDF reader.

=head1 CONSTANTS

=head2 Font IDs

    HELVETICA
    HELVETICA_BOLD
    HELVETICA_OBLIQUE
    HELVETICA_BOLDOBLIQUE
    TIMES_ROMAN
    TIMES_BOLD
    TIMES_ITALIC
    TIMES_BOLDITALIC
    COURIER
    COURIER_BOLD
    COURIER_OBLIQUE
    COURIER_BOLDOBLIQUE
    SYMBOL
    ZAPFDINGBATS

=head1 CLASS METHODS

=head2 lookup($name)

Look up a Standard 14 font by its PostScript name. Returns the font ID
constant, or -1 if not found.

    my $id = PDF::Make::Font::Std14->lookup('Helvetica-Bold');

=head2 width($font_id, $codepoint)

Get the glyph width for a Standard 14 font. The width is in units of
1/1000 em.

    my $width = PDF::Make::Font::Std14->width(
        PDF::Make::Font::Std14->HELVETICA,
        ord('A')
    );  # Returns 667

=head1 SEE ALSO

L<PDF::Make::Font>

=cut
