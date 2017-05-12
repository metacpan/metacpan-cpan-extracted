#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper need_gtk => 1, tests => 73;

my $label = Gtk2::Label -> new("Bla");
my $context = $label -> create_pango_context();

my $layout = Pango::Layout -> new($context);
isa_ok($layout, "Pango::Layout");
is($layout -> get_context(), $context);

$layout -> context_changed();

$layout -> set_text("Bla bla.");
is($layout -> get_text(), "Bla bla.");

$layout -> set_markup("Bla bla.");
is($layout -> set_markup_with_accel("Bla _bla.", "_"), "b");

my $font = Pango::FontDescription -> new();

$layout -> set_font_description($font);

SKIP: {
  skip("set_font_description was slightly borken", 0)
    unless (Pango -> CHECK_VERSION(1, 4, 0));

  $layout -> set_font_description(undef);
}

SKIP: {
  skip("new 1.8 stuff", 2)
    unless (Pango -> CHECK_VERSION(1, 8, 0));

  is($layout -> get_font_description(), undef);

  $layout -> set_font_description($font);
  isa_ok($layout -> get_font_description(), "Pango::FontDescription");
}

$layout -> set_width(23);
is($layout -> get_width(), 23);

$layout -> set_wrap("word");
is($layout -> get_wrap(), "word");

$layout -> set_indent(5);
is($layout -> get_indent(), 5);

$layout -> set_spacing(5);
is($layout -> get_spacing(), 5);

$layout -> set_justify(1);
is($layout -> get_justify(), 1);

my $attributes = $layout -> get_attributes();
isa_ok($attributes, "Pango::AttrList");

my $copy = $attributes -> copy();
$layout -> set_attributes(undef);
is($layout -> get_attributes(), undef);

$layout -> set_attributes($copy);

SKIP: {
  skip("[sg]et_auto_dir are new in 1.3.5", 1)
    unless (Pango -> CHECK_VERSION(1, 4, 0));

  $layout -> set_auto_dir(1);
  is($layout -> get_auto_dir(), 1);
}

$layout -> set_alignment("left");
is($layout -> get_alignment(), "left");

$layout -> set_tabs(Pango::TabArray -> new(8, 0));
isa_ok($layout -> get_tabs(), "Pango::TabArray");

$layout -> set_single_paragraph_mode(1);
is($layout -> get_single_paragraph_mode(), 1);

my $attribute = ($layout -> get_log_attrs())[0];
isa_ok($attribute, "HASH");

is_deeply($attribute, {
  is_line_break => 0,
  is_mandatory_break => 0,
  is_char_break => 1,
  is_white => 0,
  is_cursor_position => 1,
  is_word_start => 1,
  is_word_end => 0,
  is_sentence_boundary =>
    (Pango -> CHECK_VERSION(1, 22, 0) ? 1 : 0),
  is_sentence_start => 1,
  is_sentence_end => 0,
  Pango -> CHECK_VERSION(1, 4, 0) ?
    (backspace_deletes_character => 1) :
    (),
  Pango -> CHECK_VERSION(1, 18, 0) ?
    (is_expandable_space => 0) :
    ()
});

foreach ($layout -> index_to_pos(23),
         $layout -> get_cursor_pos(1),
         $layout -> get_extents(),
         $layout -> get_pixel_extents()) {
  isa_ok($_, "HASH");
}

my $number = qr/^\d+$/;

my ($index, $trailing) = $layout -> xy_to_index(5, 5);
like($index, $number);
like($trailing, $number);

is_deeply([$layout -> move_cursor_visually(1, 0, 0, 1)], [1, 0]);

my ($width, $height) = $layout -> get_size();
like($width, $number);
like($height, $number);

($width, $height) = $layout -> get_pixel_size();
like($width, $number);
like($height, $number);

like($layout -> get_line_count(), $number);

{
  my @lines = $layout -> get_lines();
  isa_ok($lines[0], "Pango::LayoutLine");
  is(scalar @lines, $layout -> get_line_count());

  my $line = $layout -> get_line(0);
  isa_ok($line, "Pango::LayoutLine");

  my ($outside, $index, $trailing) = $line -> x_to_index(23);
  ok(defined $outside && defined $index && defined $trailing);
  ok(defined $line -> index_to_x(0, TRUE));

  my @ranges = $line -> get_x_ranges(0, 8000);
  isa_ok($ranges[0], "ARRAY");
  is(scalar @{$ranges[0]}, 2);

  my ($ink, $logical);
  ($ink, $logical) = $line -> get_extents();
  isa_ok($ink, "HASH");
  isa_ok($logical, "HASH");
  ($ink, $logical) = $line -> get_pixel_extents();
  isa_ok($ink, "HASH");
  isa_ok($logical, "HASH");
}

{
  my $iter = $layout -> get_iter();
  isa_ok($iter, "Pango::LayoutIter");

  foreach ($iter -> get_char_extents(),
           $iter -> get_cluster_extents(),
           $iter -> get_run_extents(),
           $iter -> get_line_extents(),
           $iter -> get_layout_extents()) {
    isa_ok($_, "HASH");
  }

  my ($y0, $y1) = $iter -> get_line_yrange();
  like($y0, $number);
  like($y1, $number);

  ok($iter -> next_run());
  ok($iter -> next_char());
  ok($iter -> next_cluster());
  ok(!$iter -> next_line());
  ok($iter -> at_last_line());

  like($iter -> get_index(), $number);
  like($iter -> get_baseline(), $number);

  isa_ok($iter -> get_line(), "Pango::LayoutLine");
}

SKIP: {
  skip("[sg]et_ellipsize are new in 1.6", 1)
    unless (Pango -> CHECK_VERSION(1, 6, 0));

  $layout -> set_ellipsize("end");
  is($layout -> get_ellipsize(), "end");
}

SKIP: {
  skip "1.16 stuff", 3
    unless Pango -> CHECK_VERSION(1, 16, 0);

  isa_ok($layout -> get_line_readonly(0), "Pango::LayoutLine");
  my @lines = $layout -> get_lines_readonly();
  is(scalar @lines, $layout -> get_line_count());
  my $iter = $layout -> get_iter();
  isa_ok($iter -> get_line_readonly(), "Pango::LayoutLine");
}

SKIP: {
  skip 'new 1.20 stuff', 2
    unless (Pango -> CHECK_VERSION(1, 20, 0));

  my $iter = $layout -> get_iter();
  is($iter -> get_layout(), $layout);
  isa_ok($iter -> copy(), 'Pango::LayoutIter');
}

SKIP: {
  skip 'new 1.20 stuff', 1
    unless (Pango -> CHECK_VERSION(1, 20, 0));

  $layout -> set_height(23);
  is($layout -> get_height(), 23);
}

SKIP: {
  skip 'new 1.22 stuff', 1
    unless Pango->CHECK_VERSION(1, 22, 0);

  my $font = Pango::FontDescription -> from_string('Sans 12');
  $layout -> set_font_description($font);
  like($layout -> get_baseline(), $number);
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
