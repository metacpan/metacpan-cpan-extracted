########################################################################
# File:     20delete.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 20delete.t,v 1.1 2000/02/10 01:48:37 winters Exp $
#
# This script tests the delete and restore methods.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

require 't/common.pl';

my %Config;  ### holds config info for tests ###
load_config(\%Config);

print "1..1\n";

### eval all of the persistent code to catch any exceptions ###
eval {

  ### Test #1: Delete an object ###
  my $car = new_car(\%Config);
  my $count = $car->restore('2DEF123');
  $car->delete();
  $car = new_car(\%Config);
  $count = $car->restore_all();
  test(1, $count == 4, "restore and delete failed ($count != 4)");
};

if ($@) {
  warn "An exception occurred: $@\n";
}
