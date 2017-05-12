#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper tests => 6;

SKIP: {
  skip("PangoTabs was broken prior to 1.3.3", 6)
    unless (Pango -> CHECK_VERSION(1, 4, 0));

  my $array = Pango::TabArray -> new(8, 0);
  isa_ok($array, "Pango::TabArray");

  $array = Pango::TabArray -> new_with_positions(2, 1, "left", 8, "left", 16);
  isa_ok($array, "Pango::TabArray");

  $array -> resize(3);
  is($array -> get_size(), 3);

  $array -> set_tab(2, "left", 24);
  is_deeply([$array -> get_tab(2)], ["left", 24]);

  is_deeply([$array -> get_tabs()], ["left", 8, "left", 16, "left", 24]);

  is($array -> get_positions_in_pixels(), 1);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
