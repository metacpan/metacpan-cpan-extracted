#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper need_gtk => 1, tests => 57;

my $description = Pango::FontDescription -> new();
isa_ok($description, "Pango::FontDescription");

like($description -> hash(), qr/^\d+$/);
is($description -> equal($description), 1);

$description -> set_family("Sans");
$description -> set_family_static("Sans");
is($description -> get_family(), "Sans");

$description -> set_style("normal");
is($description -> get_style(), "normal");

$description -> set_variant("normal");
is($description -> get_variant(), "normal");

$description -> set_weight("bold");
is($description -> get_weight(), "bold");

$description -> set_stretch("condensed");
is($description -> get_stretch(), "condensed");

$description -> set_size(23);
is($description -> get_size(), 23);

isa_ok($description -> get_set_fields(), "Pango::FontMask");
$description -> unset_fields([qw(size stretch)]);

$description -> merge($description, 1);
$description -> merge_static($description, 1);

ok(!$description -> better_match($description, $description));
ok($description -> better_match(undef, $description));

$description = Pango::FontDescription -> from_string("Sans 12");
isa_ok($description, "Pango::FontDescription");

is($description -> to_string(), "Sans 12");
ok(defined($description -> to_filename()));

SKIP: {
  skip("new 1.8 stuff", 1)
    unless (Pango -> CHECK_VERSION(1, 8, 0));

  $description -> set_absolute_size(23.42);
  is($description -> get_size_is_absolute(), TRUE);
}

SKIP: {
  skip("new 1.16 stuff", 1)
    unless (Pango -> CHECK_VERSION(1, 16, 0));

  $description -> set_gravity("south");
  is($description -> get_gravity(), "south");
}

###############################################################################

my $label = Gtk2::Label -> new("Bla");
my $context = $label -> create_pango_context();
my $font = $context -> load_font($description);
my $language = Gtk2 -> get_default_language();

my $number = qr/^-?\d+$/;

isa_ok($font -> describe(), "Pango::FontDescription");

SKIP: {
  skip "new 1.14 stuff", 1
    unless Pango -> CHECK_VERSION(1, 14, 0);

  isa_ok($font -> describe_with_absolute_size(), "Pango::FontDescription");
}

foreach my $rectangle ($font -> get_glyph_extents(23)) {
  foreach my $key (qw(x y width height)) {
    like($rectangle -> { $key }, $number);
  }
}

my $metrics = $font -> get_metrics($language);
isa_ok($metrics, "Pango::FontMetrics");

like($metrics -> get_ascent(), $number);
like($metrics -> get_descent(), $number);
like($metrics -> get_approximate_char_width(), $number);
like($metrics -> get_approximate_digit_width(), $number);

SKIP: {
  skip("new 1.6 stuff", 4)
    unless (Pango -> CHECK_VERSION(1, 6, 0));

  like($metrics -> get_underline_position(), $number);
  like($metrics -> get_underline_thickness(), $number);
  like($metrics -> get_strikethrough_position(), $number);
  like($metrics -> get_strikethrough_thickness(), $number);
}

SKIP: {
  skip("new 1.10 stuff", 1)
    unless (Pango -> CHECK_VERSION(1, 10, 0));

  isa_ok($font -> get_font_map(), "Pango::FontMap");
}

###############################################################################

like(int(Pango -> scale()), $number);
like(int(Pango -> scale_xx_small()), $number);
like(int(Pango -> scale_x_small()), $number);
like(int(Pango -> scale_small()), $number);
like(int(Pango -> scale_medium()), $number);
like(int(Pango -> scale_large()), $number);
like(int(Pango -> scale_x_large()), $number);
like(int(Pango -> scale_xx_large()), $number);
like(int(Pango -> PANGO_PIXELS(23)), $number);
like(int(Pango -> pixels(23)), $number);

###############################################################################

my @families = $context->list_families;
ok (@families > 0, 'got a list of families');
isa_ok ($families[0], 'Pango::FontFamily');
ok ($families[0]->get_name, 'get_name works');
SKIP: {
  skip "is_monospace is new in 1.4.0", 1
    unless Pango->CHECK_VERSION (1, 4, 0);
  # we don't really have a way of knowing if this font should actually
  # be monospaced, so just check that the function doesn't die.
  $families[0]->is_monospace;
  ok (1, 'is_monospace works');
}

my @faces = $families[0]->list_faces;
#print "faces @faces\n";
ok (@faces > 0, 'got a list of faces');
isa_ok ($faces[0], 'Pango::FontFace');
my $desc = $faces[0]->describe;
isa_ok ($desc, 'Pango::FontDescription');
ok ($faces[0]->get_face_name);
SKIP: {
  skip "list_sizes is new in 1.4.0", 1
    unless Pango->CHECK_VERSION (1, 4, 0);
  # again, whether we'll get sizes depends on whether this first font and
  # face is a bitmapped font.  we can't know that, so just test that the
  # call does not result in a crash.
  my @sizes = $faces[0]->list_sizes;
  #print "sizes @sizes\n";
  ok (1, 'list_sizes did not crash');
}

SKIP: {
  skip("new 1.18 stuff", 1)
    unless (Pango -> CHECK_VERSION(1, 18, 0));

  ok(defined $faces[0]->is_synthesized);
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
