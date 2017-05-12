#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper;

if (UNIVERSAL::can("Pango::Cairo::FontMap", "new") &&
    Pango -> CHECK_VERSION(1, 10, 0)) {
  plan tests => 22;
} else {
  plan skip_all => "PangoCairo stuff: need Cairo and pango >= 1.10.0";
}

my $fontmap = Pango::Cairo::FontMap -> new();
isa_ok($fontmap, "Pango::Cairo::FontMap");
isa_ok($fontmap, "Pango::FontMap");

SKIP: {
  skip 'new 1.18 stuff', 3
    unless Pango -> CHECK_VERSION(1, 18, 0);

  $fontmap = Pango::Cairo::FontMap -> new_for_font_type('ft');

  skip 'new_for_font_type returned undef', 3
    unless defined $fontmap;

  isa_ok($fontmap, "Pango::Cairo::FontMap");
  isa_ok($fontmap, "Pango::FontMap");
  is($fontmap -> get_font_type(), 'ft');
}

$fontmap = Pango::Cairo::FontMap -> get_default();
isa_ok($fontmap, "Pango::Cairo::FontMap");
isa_ok($fontmap, "Pango::FontMap");

$fontmap -> set_resolution(72);
is($fontmap -> get_resolution(), 72);

my $context = $fontmap -> create_context();
isa_ok($context, "Pango::Context");

# Just to make sure this is a valid Pango::FontMap
isa_ok(($fontmap -> list_families())[0], "Pango::FontFamily");

my $target = Cairo::ImageSurface -> create("argb32", 100, 100);
my $cr = Cairo::Context -> create($target);

Pango::Cairo::update_context($cr, $context);

my $options = Cairo::FontOptions -> create();

# Function interface
{
  Pango::Cairo::Context::set_font_options($context, $options);
  isa_ok(Pango::Cairo::Context::get_font_options($context),
         "Cairo::FontOptions");

  Pango::Cairo::Context::set_resolution($context, 72);
  is(Pango::Cairo::Context::get_resolution($context), 72);
}

# Method interface
{
  isa_ok($context, "Pango::Cairo::Context");

  $context -> set_font_options($options);
  isa_ok($context -> get_font_options(), "Cairo::FontOptions");

  $context -> set_resolution(72);
  is($context -> get_resolution(), 72);
}

my $layout = Pango::Cairo::create_layout($cr);
isa_ok($layout, "Pango::Layout");

my $line = $layout -> get_line(0);

Pango::Cairo::show_layout_line($cr, $line);
Pango::Cairo::show_layout($cr, $layout);
Pango::Cairo::layout_line_path($cr, $line);
Pango::Cairo::layout_path($cr, $layout);

Pango::Cairo::update_layout($cr, $layout);

# FIXME: pango_cairo_show_glyph_string, pango_cairo_glyph_string_path.

SKIP: {
  skip "error line stuff", 0
    unless Pango -> CHECK_VERSION(1, 14, 0);

  Pango::Cairo::show_error_underline($cr, 23, 42, 5, 5);
  Pango::Cairo::error_underline_path($cr, 23, 42, 5, 5);
}

SKIP: {
  skip 'new 1.18 stuff', 6
    unless Pango -> CHECK_VERSION(1, 18, 0);

  $context -> set_shape_renderer(undef, undef);

  my $target = Cairo::ImageSurface -> create('argb32', 100, 100);
  my $cr = Cairo::Context -> create($target);

  my $layout = Pango::Cairo::create_layout($cr);
  Pango::Cairo::Context::set_shape_renderer(
    $layout -> get_context(),
    sub {
      my ($cr, $shape, $do_path, $data) = @_;

      isa_ok($cr, 'Cairo::Context');
      isa_ok($shape, 'Pango::AttrShape');
      ok(defined $do_path);
      is($data, 'bla');
    },
    'bla');
  $layout -> set_text('Bla');

  my $ink     = { x => 23, y => 42, width => 10, height => 15 };
  my $logical = { x => 42, y => 23, width => 15, height => 10 };
  my $attr = Pango::AttrShape -> new($ink, $logical, 0, 1);
  my $list = Pango::AttrList -> new();
  $list -> insert($attr);
  $layout -> set_attributes($list);

  Pango::Cairo::show_layout($cr, $layout);

  my $desc = Pango::FontDescription -> from_string('Sans 10');
  my $font = $fontmap -> load_font($context, $desc);
  skip 'could not load font', 2
    unless defined $font;
  isa_ok($font, 'Pango::Cairo::Font');
  isa_ok($font -> get_scaled_font(), 'Cairo::ScaledFont');
}

__END__

Copyright (C) 2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
