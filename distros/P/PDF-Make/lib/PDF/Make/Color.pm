package PDF::Make::Color;

use strict;
use warnings;

our $VERSION = '0.04';

use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Color - Color spaces and color conversion

=head1 SYNOPSIS

    use PDF::Make::Document;
    use PDF::Make::Color;

    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);

    # Create an sRGB color space (CalRGB with D65 white point)
    my $srgb = PDF::Make::Color->srgb;
    $srgb->write_to_doc($doc);

    # Create a spot (separation) color
    my $spot = PDF::Make::Color->separation('PANTONE 185 C',
        0, 0.81, 0.69, 0);  # CMYK fallback
    $spot->write_to_doc($doc);

    # Inspect
    print $srgb->name, "\n";        # sRGB
    print $srgb->components, "\n";  # 3

    # Color conversions (class methods)
    my ($c, $m, $y, $k) = PDF::Make::Color->rgb_to_cmyk(1.0, 0, 0);
    my ($r, $g, $b)     = PDF::Make::Color->cmyk_to_rgb(0, 1, 1, 0);
    my ($r2, $g2, $b2)  = PDF::Make::Color->hex_to_rgb('#ff6600');

=head1 DESCRIPTION

C<PDF::Make::Color> manages PDF color spaces and provides color conversion
utilities. Supports Device color spaces (RGB, CMYK, Gray), CIE-based spaces
(sRGB as CalRGB), and Separation spaces (spot colors).

=head1 CLASS METHODS

=head2 srgb()

    my $cs = PDF::Make::Color->srgb;

Creates an sRGB color space object (CalRGB with D65 white point and sRGB
gamma/matrix). This is the standard color space for screen-oriented PDFs.

=head2 separation($name, $c, $m, $y, $k)

    my $cs = PDF::Make::Color->separation('Reflex Blue',
        1.0, 0.8, 0, 0.02);

Creates a Separation (spot) color space. The CMYK values define the fallback
appearance when the spot ink is not available.

=over 4

=item C<$name> - Spot color name (e.g. 'PANTONE 185 C')

=item C<$c, $m, $y, $k> - CMYK fallback values (0.0 to 1.0)

=back

=head2 rgb_to_cmyk($r, $g, $b)

    my ($c, $m, $y, $k) = PDF::Make::Color->rgb_to_cmyk(1.0, 0.5, 0);

Converts RGB values (0.0-1.0) to CMYK (0.0-1.0). Uses a simple UCR model.

=head2 cmyk_to_rgb($c, $m, $y, $k)

    my ($r, $g, $b) = PDF::Make::Color->cmyk_to_rgb(0, 1, 1, 0);

Converts CMYK values (0.0-1.0) to RGB (0.0-1.0).

=head2 hex_to_rgb($hex)

    my ($r, $g, $b) = PDF::Make::Color->hex_to_rgb('#ff6600');
    my ($r, $g, $b) = PDF::Make::Color->hex_to_rgb('3498db');

Converts a hex color string to RGB (0.0-1.0). Accepts with or without
leading C<#>. Croaks on invalid input.

=head1 INSTANCE METHODS

=head2 name()

    my $n = $cs->name;

Returns the color space name (e.g. 'sRGB', 'Reflex Blue').

=head2 components()

    my $n = $cs->components;

Returns the number of color components (3 for RGB, 4 for CMYK, 1 for
Separation).

=head2 write_to_doc($doc)

    my $obj_num = $cs->write_to_doc($doc);

Writes the color space dictionary into the document. Returns the PDF object
number.

=head1 SEE ALSO

L<PDF::Make::Document>, L<PDF::Make::Canvas>, L<PDF::Make::Builder>

=cut
