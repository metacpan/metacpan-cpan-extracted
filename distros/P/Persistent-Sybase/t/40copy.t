########################################################################
# File:     40copy.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 40copy.t,v 1.1 2000/02/10 01:48:37 winters Exp $
#
# This script tests many methods while copying objects from one data store
# to another.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

require 't/common.pl';

my %Config;  ### holds config info for tests ###
load_config(\%Config);

print "1..2\n";

### eval all of the persistent code to catch any exceptions ###
eval {

  ### Test #1 and #2: Copy objects to new data store ###
  my $car = new_car(\%Config);
  my $car2 = new_car(\%Config, 'File');
  my $count = $car->restore_all();
  while ($car->restore_next()) {
    $car2->license($car->license);
    $car2->make($car->make);
    $car2->model($car->model);
    $car2->year($car->year);
    $car2->color($car->color);
    $car2->insert;
  }
  $car = new_car(\%Config);
  $car2 = new_car(\%Config, 'File');
  $count = $car->restore_all("license");
  my $count2 = $car2->restore_all("license");
  test(1, $count == $count2, "copy failed ($count != $count2)");
  $car->restore_next();
  $car2->restore_next();
  test(2, $car->license eq $car2->license && $car->make eq $car2->make,
       sprintf("copy failed (%s ne %s || %s ne %s)",
	       $car->license, $car2->license, $car->make, $car2->make));
};

if ($@) {
  warn "An exception occurred: $@\n";
}
