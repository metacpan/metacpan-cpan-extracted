#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper need_gtk => 1, tests => 7;

my $label = Gtk2::Label -> new("Bla");
my $context = $label -> create_pango_context();
my $font = Pango::FontDescription -> from_string("Sans 12");
my $language = Gtk2 -> get_default_language();
my $set = $context -> load_fontset($font, $language);

isa_ok($set -> get_font(23), "Pango::Font");
isa_ok($set -> get_metrics(), "Pango::FontMetrics");

SKIP: {
  skip("foreach is new in 1.4", 5)
    unless (Pango -> CHECK_VERSION(1, 4, 0));

  $set -> foreach(sub {
    isa_ok(shift(), "Pango::Fontset");
    isa_ok(shift(), "Pango::Font");
    return 1;
  });

  $set -> foreach(sub {
    isa_ok(shift(), "Pango::Fontset");
    isa_ok(shift(), "Pango::Font");
    is(shift(), "bla");
    return 1;
  }, "bla");
}

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
