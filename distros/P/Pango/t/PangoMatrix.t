#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper tests => 48;

SKIP: {
  skip("PangoMatrix is new in 1.6", 44)
    unless (Pango -> CHECK_VERSION(1, 6, 0));

  my $matrix = Pango::Matrix -> new(2.3, 2.3, 2.3, 2.3, 2.3, 2.3);
  isa_ok($matrix, "Pango::Matrix");
  delta_ok($matrix -> xx, 2.3);
  delta_ok($matrix -> xy, 2.3);
  delta_ok($matrix -> yx, 2.3);
  delta_ok($matrix -> yy, 2.3);
  delta_ok($matrix -> x0, 2.3);
  delta_ok($matrix -> y0, 2.3);

  $matrix = Pango::Matrix -> new();
  isa_ok($matrix, "Pango::Matrix");
  is($matrix -> xx, 1);
  is($matrix -> xy, 0);
  is($matrix -> yx, 0);
  is($matrix -> yy, 1);
  is($matrix -> x0, 0);
  is($matrix -> y0, 0);

  $matrix -> translate(5, 5);
  is($matrix -> xx, 1);
  is($matrix -> xy, 0);
  is($matrix -> yx, 0);
  is($matrix -> yy, 1);
  is($matrix -> x0, 5);
  is($matrix -> y0, 5);

  $matrix -> scale(2, 2);
  is($matrix -> xx, 2);
  is($matrix -> xy, 0);
  is($matrix -> yx, 0);
  is($matrix -> yy, 2);
  is($matrix -> x0, 5);
  is($matrix -> y0, 5);

  $matrix -> rotate(0);
  is($matrix -> xx, 2);
  is($matrix -> xy, 0);
  is($matrix -> yx, 0);
  is($matrix -> yy, 2);
  is($matrix -> x0, 5);
  is($matrix -> y0, 5);

  $matrix -> concat($matrix);
  is($matrix -> xx, 4);
  is($matrix -> xy, 0);
  is($matrix -> yx, 0);
  is($matrix -> yy, 4);
  is($matrix -> x0, 15);
  is($matrix -> y0, 15);

  $matrix -> xx(2.3);
  $matrix -> xy(2.3);
  $matrix -> yx(2.3);
  $matrix -> yy(2.3);
  $matrix -> x0(2.3);
  $matrix -> y0(2.3);
  delta_ok($matrix -> xx, 2.3);
  delta_ok($matrix -> xy, 2.3);
  delta_ok($matrix -> yx, 2.3);
  delta_ok($matrix -> yy, 2.3);
  delta_ok($matrix -> x0, 2.3);
  delta_ok($matrix -> y0, 2.3);
}

SKIP: {
  skip "1.16 stuff", 4
    unless Pango -> CHECK_VERSION(1, 16, 0);

  my $matrix = Pango::Matrix -> new(); # identity

  is_deeply([$matrix -> transform_distance(1.0, 2.0)], [1.0, 2.0]);

  is_deeply([$matrix -> transform_point(1.0, 2.0)], [1.0, 2.0]);

  my $rect = {x => 1.0, y => 2.0, width => 23.0, height => 42.0};
  is_deeply($matrix -> transform_rectangle($rect), $rect);
  is_deeply($matrix -> transform_pixel_rectangle($rect), $rect);
}

__END__

Copyright (C) 2007 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
