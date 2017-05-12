#---------------------------------------------------------------------
package Font_Test;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 31 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Compare our font metrics against Font::AFM
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '2.00';

use strict;
use warnings;
use Exporter 5.57 'import';
use constant number_of_tests => 275;
use Test::More tests => number_of_tests;

use PostScript::File::Metrics;

our @EXPORT = qw(test_font);

our %attribute = qw(
  FullName           full_name
  FamilyName         family
  Weight             weight
  IsFixedPitch       fixed_pitch
  ItalicAngle        italic_angle
  FontBBox           font_bbox
);

our %dimension_attribute = qw(
  UnderlinePosition  underline_position
  UnderlineThickness underline_thickness
  CapHeight          cap_height
  XHeight            x_height
  Ascender           ascender
  Descender          descender
);
# We don't test this:
#  Version            version

#=====================================================================

sub test_font
{
  my ($font) = @_;

  my $size = 125;
  my $factor = 1000 / $size;

  my $metrics = PostScript::File::Metrics->new($font, $size, 'iso-8859-1');

  isa_ok($metrics, 'PostScript::File::Metrics');

  ok(!$INC{'PostScript/File/Metrics/Loader.pm'},
     'used pre-compiled metrics');

  SKIP: {
    my $testsInBlock = number_of_tests - 2;

    # RECOMMEND PREREQ: Font::AFM
    # Construct the Font::AFM object, or skip the remaining tests:
    eval { require Font::AFM };

    skip "Font::AFM not installed", $testsInBlock if $@;

    my $afm = eval { Font::AFM->new($font) };

    skip "Font::AFM can't find $font.afm", $testsInBlock if $@;

    # Compare the font attributes:
    foreach my $afm_method (sort keys %attribute) {
      my $metrics_method = $attribute{$afm_method};
      my $got = $metrics->$metrics_method;
      if ($afm_method eq 'FontBBox') {
        $_ *= $factor for @$got;
        $got = "@$got" ;
      } # end if FontBBox
      $got = $got ? 'true' : 'false' if $afm_method eq 'IsFixedPitch';
      is($got, $afm->$afm_method, $afm_method);
    }

    # Compare the font dimension attributes:
    foreach my $afm_method (sort keys %dimension_attribute) {
      my $metrics_method = $dimension_attribute{$afm_method};
      my $got = $metrics->$metrics_method;
      is($got * $factor, $afm->$afm_method, $afm_method);
    }

    # Compare the character widths:
    my $wx = $afm->latin1_wx_table;
    $metrics->set_auto_hyphen(0); # Font::AFM doesn't translate hyphen-minus
    $metrics->set_size(undef);    # Switch to default size to match Font::AFM

    for my $char (0 .. 255) {
      my $name = sprintf 'width of char \%03o, \x%02X', $char, $char;
      $name = sprintf '%s (%c)', $name, $char
          if $char >= 0x20 and $char < 0x7F;
      is( $metrics->width(pack 'C', $char), $wx->[$char], $name);
    } # end for $char

    # Test width vs stringwidth:
    $metrics->set_size($size);  # Switch back to old size
    while (<DATA>) {
      chomp $_;
      is( $metrics->width($_), $afm->stringwidth($_, $size), $_);
    }

  } # end SKIP
} # end test_font

#=====================================================================
# Package Return Value:

1;

__DATA__
Now is the time for all good men to come to the aid of their country.
The quick brown fox jumps over the lazy dog.
car­wash
car-wash
-1
