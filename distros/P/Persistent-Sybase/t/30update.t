########################################################################
# File:     30update.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 30update.t,v 1.1 2000/02/10 01:48:37 winters Exp $
#
# This script tests the update and restore_where methods.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

require 't/common.pl';

my %Config;  ### holds config info for tests ###
load_config(\%Config);

print "1..3\n";

### eval all of the persistent code to catch any exceptions ###
eval {

  ### Tests #1, #2, and #3: Update 2 objects ###
  my $car = new_car(\%Config);
  my $count = $car->restore_where(sprintf("make = %s", $car->quote("Ford")));
  test(1, $count == 2, "restore_where failed ($count != 2)");
  while ($car->restore_next()) {
    $car->color('Pink');
    $car->update();
  }
  $car = new_car(\%Config);
  $count = $car->restore_where(sprintf("make = %s and color = %s",
				       $car->quote("Ford"),
				       $car->quote("Pink")));
  test(2, $count == 2, "restore_where failed ($count != 2)");
  $car->restore_next();
  my $color = $car->color();
  test(3, $color eq 'Pink', "update failed ($color ne 'Pink')");
};

if ($@) {
  warn "An exception occurred: $@\n";
}
