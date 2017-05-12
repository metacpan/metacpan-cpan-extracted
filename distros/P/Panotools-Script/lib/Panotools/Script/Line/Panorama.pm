package Panotools::Script::Line::Panorama;

use strict;
use warnings;
use Panotools::Script::Line;

=head1 NAME

Panotools::Script::Line::Panorama - Panotools panorama parameters

=head1 SYNOPSIS

Panorama parameters are described by a 'p' line

=head1 DESCRIPTION

  w1000        width in pixels
  h600         height in pixels
  f0           projection format,
                   0 - rectilinear (for printing and viewing)
                   1 - Cylindrical (for Printing and QTVR)
                   2 - Equirectangular ( for Spherical panos), default
                   3 - full-frame fisheye
                   4 - stereographic
                   5 - mercator
                   6 - transverse mercator
                   7 - sinusoidal
                   8 - Lambert Equal Area Cylindrical
                   9 - Lambert Azimuthal
                  10 - Albers Equal Area Conical
                  11 - Miller Cylindrical
                  12 - Panini
                  13 - Architectural
                  14 - Orthographic
                  15 - Equisolid
                  16 - Equirectangular Panini
                  17 - Biplane
                  18 - Triplane
                  19 - Panini_General
                  20 - Thoby
                  21 - Hammer

  v360         horizontal field of view of panorama (default 360)
  nPICT        Panorama file format, one of:
                   PNG           png-format, 8 & 16 bit supported
                   TIFF          tiff-format, all tiff types supported (8,16,32 bit int, float, double)
                   TIFF_m        tiff-format, multi-file, one image per file
                                   alpha layer with non-feathered clip mask at image border
                   TIFF_multilayer  tiff-format, multi-image-file, all files in one image
                                   alpha layer with non-feathered clip mask at image border
                                   This filetype is supported by The GIMP
                   JPEG          Panoramic image in jpeg-format.
                some more supported file formats (mostly only 8 bit support)
                   PNM, PGM, BMP, SUN, VIFF

               Special options for TIFF output:
               n"TIFF c:NONE"
                   c - select TIFF compression, possible options: NONE, LZW, DEFLATE

               Special options for TIFF_m and TIFF_multilayer output:
               n"TIFF c:NONE r:CROP"
                   c - TIFF compression, possible options NONE, LZW, DEFLATE
                   r - output only used image area (cropped output). The crop offsets
                       are stored in the POSITIONX and POSITONY tiff tags
                   p1 - save coordinate images (useful for further programs, like vignetting correction)

               Special options for JPEG output:
               n"JPEG q95"
                   q - jpeg quality

  u10          width of feather for stitching all images. default:10
  k1           attempt color & brightness correction using image number as anchor
  b1           attempt brightness correction with no color change using image number as anchor
  d1           attempt color correction with no brightness change using image number as anchor
                   Do not use more than one of k, d, b.This is new method of correcting

  E1           exposure value for final panorama
  R1           stitching mode: 0: normal LDR mode, 1: HDR mode
  T"UINT8"     bitdepth of output images, possible values are
               UINT8  -  8 bit unsigned
               UINT16 - 16 bit unsigned
               FLOAT  - 32 bit floating point
               By default the bit depth of the input images is used.
  S100,600,100,800   Selection(left,right,top,bottom), Only pixels inside the rectangle
                     will be rendered. Images that do not contain pixels in this area
                     are not rendered/created.
  P"0 60"      Projection parameters. e.g. Albers Equal Area Conical requires extra parameters.

=cut

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

sub _defaults
{
    my $self = shift;
    $self->{w} = 1000;
    $self->{h} = 500;
    $self->{v} = 360.0;
    $self->{n} = '"JPEG q100"';
    $self->{E} = 0;
    $self->{f} = 2;
    $self->{R} = 0;
}

sub _valid { '^([bdfhknuvwERTSP])(.*)' }

sub Identifier
{
    my $self = shift;
    return "p";
}

sub Report
{
    my $self = shift;
    my @report;

    my $format = 'UNKNOWN';
    $format = "Rectilinear" if $self->{f} == 0;
    $format = "Cylindrical" if $self->{f} == 1;
    $format = "Equirectangular" if $self->{f} == 2;
    $format = "Fisheye" if $self->{f} == 3;
    $format = "Stereographic" if $self->{f} == 4;
    $format = "Mercator" if $self->{f} == 5;
    $format = "Transverse mercator" if $self->{f} == 6;
    $format = "Sinusoidal" if $self->{f} == 7;
    $format = "Lambert Equal Area Cylindrical" if $self->{f} == 8;
    $format = "Lambert Azimuthal" if $self->{f} == 9;
    $format = "Albers Equal Area Conical" if $self->{f} == 10;
    $format = "Miller Cylindrical" if $self->{f} == 11;
    $format = "Panini" if $self->{f} == 12;
    $format = "Architectural" if $self->{f} == 13;
    $format = "Orthographic" if $self->{f} == 14;
    $format = "Equisolid" if $self->{f} == 15;
    $format = "Equirectangular Panini" if $self->{f} == 16;
    $format = "Biplane" if $self->{f} == 17;
    $format = "Triplane" if $self->{f} == 18;

    my $mode = "LDR";
    $mode = "HDR" if defined $self->{R} and $self->{R} == 1;

    push @report, ['Dimensions', $self->{w} .'x'. $self->{h}];
    push @report, ['Megapixels', int ($self->{w} * $self->{h} / 1024 / 1024 * 10) / 10];
    push @report, ['Format', $format];
    push @report, ['Horizontal Field of View', $self->{v}];
    push @report, ['File type', $self->{n}];
    push @report, ['Exposure Value', $self->{E}];
    push @report, ['Stitching mode', $mode] if defined $mode;
    push @report, ['Bit depth', $self->{T}] if defined $self->{T};
    push @report, ['Selection area', $self->{S}] if defined $self->{S};
    [@report];
}

1;
