package QR::Code;

use 5.016;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('QR::Code', $VERSION);

1;

__END__

=head1 NAME

QR::Code - QR symbols rendered as SVG, with logos, shapes and colours

=head1 SYNOPSIS

    use QR::Code;

    my $svg = QR::Code->svg('otpauth://totp/...');

    # a logo in the middle: a word, artwork, or an image file
    $svg = QR::Code->svg($uri, logo => 'Punk');
    $svg = QR::Code->svg($uri, logo => { svg  => $markup });
    $svg = QR::Code->svg($uri, logo => { file => 'camel.png' });

    # styled
    $svg = QR::Code->svg($uri, style => {
        shape  => 'dot',
        finder => 'circle',
        dark   => '#102a43',
        light  => '#f0f4f8',
    });

    my $matrix = QR::Code->matrix($uri, ecc => 'Q');
    print QR::Code->pbm($uri);

=head1 DESCRIPTION

QR::Code encodes byte mode QR symbols, versions 1 to 15, at all four
error correction levels, and serialises them to SVG. It has no runtime
dependencies and links no libraries.

The output is SVG rather than a raster because a QR is fundamentally
vector: it scales to any rendered size without resampling, embeds as a
C<data:> URI in an C<img> tag, and needs no compressor or container. A
caller who wants a raster has C<matrix> and can encode one.

=head1 METHODS

=head2 matrix

    my $mod = QR::Code->matrix($data, %options);
    my ($mod, $fixed, $version, $mask, $size) = QR::Code->matrix($data);

Encodes C<$data> and returns the symbol as an arrayref of arrayrefs of
0 and 1, one entry per module, 1 dark. In list context also returns the
function pattern map (same shape, 1 where the module belongs to a
finder, timing, alignment, format or version pattern), the version, the
mask actually chosen, and the module count per side.

Options: C<ecc>, C<version>. No quiet zone is included; the matrix is
the symbol itself.

=head2 svg

    my $svg = QR::Code->svg($data, %options);
    my ($svg, $info) = QR::Code->svg($data, %options);

Returns an SVG document as a string. In list context also returns a
hashref describing the symbol: C<version>, C<ecc>, C<mask>, C<size>,
and for a symbol with a logo a C<logo> hashref with the reserved box
(C<x>, C<y>, C<width>, C<height>, in modules), the number of modules
it C<covered>, and any C<function_hits> with their coordinates.

Options: C<ecc>, C<version>, C<quiet>, C<logo>, C<style>.

=head2 analyse

    my $info = QR::Code->analyse($data, %options);

What C<svg> would produce, without keeping the markup: the C<svg> info
hashref plus C<capacity> (the byte capacity of the chosen version at
the chosen level) and, with a logo, the flattened C<logo_covered>,
C<logo_function_hit>, C<logo_box_w> and C<logo_box_h>. Takes the same
options as C<svg>.

=head2 pbm

    print QR::Code->pbm($data, %options);

The symbol as P1 netpbm text, quiet zone included. For tests and
terminals.

=head1 OPTIONS

=over 4

=item ecc

Error correction level: C<L>, C<M>, C<Q> or C<H>. The default is C<M>,
or C<H> when a logo is present. A symbol shown on a screen and scanned
from close range wants different redundancy than one printed small on
a box; when in doubt, leave it alone.

=item version

Force a symbol version, 1 to 15. By default the smallest version whose
capacity holds the payload is chosen, and that default is also the
robust choice: at a fixed rendered size, a larger version means
smaller modules, and smaller modules are what fail under blur.

=item quiet

The quiet zone width in modules. The default of 4 is the spec minimum,
and shrinking it is the single most common reason a generated QR fails
to scan. Lower it only for a surround you control and have tested.

=back

=head1 THE CENTRE LOGO

    logo => 'Punk'
    logo => { text  => 'Punk', em => 6 }
    logo => { svg   => $markup }
    logo => { image => $bytes }
    logo => { file  => $path }

=head1 STYLE

    style => {
        shape  => 'rounded',           # square | rounded | dot
        radius => 0.3,                 # in modules
        finder => 'circle',            # square | rounded | circle
        dark   => '#102a43',
        light  => '#f0f4f8',           # or 'none' for transparent
        finder_dark => '#d64545',
        gradient => {
            type  => 'linear',         # linear | radial
            angle => 45,
            stops => ['#5e60ce', '#48bfe3'],
        },
    }

Every styling option is a way to produce a symbol that does not scan,
so each carries a rule:

=over 4

=item Colour is luminance

A decoder converts to luminance and thresholds; it never sees hue. So
colours are given as hex (C<#rgb>, C<#rrggbb> or C<#rrggbbaa> with
full alpha) and every dark-role colour is checked against C<light> for
luminance contrast. Too small a gap croaks. Dark lighter than light
croaks too: decoders assume dark modules on a light ground, and the
ones that tolerate inversion are a minority.

C<< light => 'none' >> renders no background. The effective ground
becomes whatever sits behind the symbol, which the contrast check
cannot see; the caller owns the result.

=item Module shapes

C<rounded> curves only the corners whose neighbours are light, so runs
of modules stay fused into solid bars; rounding modules individually
would open a gap at every joint and read as contrast loss under blur.
C<dot> draws circles: decoders sample module centres, so dots scan,
but the radius has a floor below which they stop surviving blur, and
radii under it croak.

=item Finder shapes

Finders are always drawn as solid shapes, never as their 33 modules,
because the locator wants an unbroken 1:1:3:1:1 dark-light run and
gaps break it. The C<circle> form keeps exactly that ratio along the
line through its centre, which is the line the locator tests - and
B<only> along that line, so circles are the tightest-margin choice of
the three. Measured: each style option decodes on its own, and circle
finders decode alone, but circles stacked with a gradient and a logo
fail a real decoder at some raster scales while passing at others.
Stack styles on C<square> or C<rounded> finders; save C<circle> for
symbols styled with nothing else.

=item Gradients

A gradient applies to the modules and never to the finders, which keep
their flat colour: the locator's ratio test is a run of samples along
one line, and a gradient crossing the threshold mid-finder is exactly
the failure the flat colour rules out. Every stop must pass the same
contrast check as a flat dark, so the worst stop gates.

=back

=head1 THE C ABI

The distribution installs C<qr_abi.h> and exposes a function table
through C<QR::Code::_abi_ptr>, so another XS module can encode without
calling back into Perl. The table holds C<matrix>, C<svg> and
C<free_fn>, and is append-only.

Check the table version with C<< version <= QR_ABI_VERSION >>, never
with equality: members are only ever added, and an equality check
turns every addition into a breaking change.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut
