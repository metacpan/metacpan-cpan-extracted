#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper tests => 4;

SKIP: {
  skip "PangoGravity", 4
    unless Pango->CHECK_VERSION (1, 16, 0);

  is (Pango::Gravity::to_rotation ('south'), 0.0);
  ok (!Pango::Gravity::is_vertical ('south'));

  my $matrix = Pango::Matrix->new;
  is (Pango::Gravity::get_for_matrix ($matrix), 'south');

  is (Pango::Gravity::get_for_script ('common', 'south', 'strong'), 'south');
}

__END__

Copyright (C) 2007 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
