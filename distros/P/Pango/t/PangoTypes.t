#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper tests => 9;

SKIP: {
  skip("find_base_dir is new in 1.4", 1)
    unless (Pango -> CHECK_VERSION(1, 4, 0));

  is(Pango -> find_base_dir("urgs"), "ltr");
}

my $language = Pango::Language -> from_string("de_DE");
isa_ok($language, "Pango::Language");
is($language -> to_string(), "de-de");
is($language -> matches("*"), 1);

SKIP: {
  skip "1.16 stuff", 5
    unless Pango -> CHECK_VERSION(1, 16, 0);

  isa_ok(Pango::Language -> get_default(), "Pango::Language");

  is(Pango::units_from_double(Pango::units_to_double(23)), 23);

  my $rect = {x => 1.0, y => 2.0, width => 23.0, height => 42.0};
  my ($new_ink, $new_logical) = Pango::extents_to_pixels($rect, $rect);
  isa_ok($new_ink, "HASH");
  isa_ok($new_logical, "HASH");

  is_deeply([Pango::extents_to_pixels(undef, undef)], [undef, undef]);
}

__END__

Copyright (C) 2004-2007 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
