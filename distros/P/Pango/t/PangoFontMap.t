#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper need_gtk => 1, tests => 4;

my $label = Gtk2::Label -> new("Bla");

my $context = $label -> create_pango_context();
isa_ok($context, "Pango::Context");

SKIP: {
  skip("get_font_map is new in 1.6", 3)
    unless (Pango -> CHECK_VERSION(1, 6, 0));

  my $map = $context -> get_font_map();
  my $desc = Pango::FontDescription -> from_string("Sans 12");
  my $lang = Pango::Language -> from_string("de_DE");

  isa_ok($map -> load_font($context, $desc), "Pango::Font");
  isa_ok($map -> load_fontset($context, $desc, $lang), "Pango::Fontset");
  isa_ok(($map -> list_families())[0], "Pango::FontFamily");
}

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
