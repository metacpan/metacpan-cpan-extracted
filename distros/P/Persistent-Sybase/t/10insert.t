########################################################################
# File:     10insert.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 10insert.t,v 1.1 2000/02/10 01:48:37 winters Exp $
#
# This script tests the insert and restore_all methods.
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

  ### Test #1: Insert 5 objects ###
  my $car = new_car(\%Config);

  $car->license('1ABC123');
  $car->make('Ford');
  $car->model('Contour');
  $car->year('1995');
  $car->color('Blue');
  $car->insert();

  $car->license('2DEF123');
  $car->make('Chevrolet');
  $car->model('Monte Carlo');
  $car->year('1985');
  $car->color('Green');
  $car->insert();

  $car->license('3GHI123');
  $car->make('Ford');
  $car->model('Aerostar');
  $car->year('2000');
  $car->color('Silver');
  $car->insert();

  $car->license('4JKL123');
  $car->make('Toyota');
  $car->model('Sienna');
  $car->year('2000');
  $car->color('Sand');
  $car->insert();

  $car->license('5MNO123');
  $car->make('Nissan');
  $car->model('Quest');
  $car->year('2000');
  $car->color('Red');
  $car->insert();

  $car = new_car(\%Config);
  my $count = $car->restore_all();
  test(1, $count == 5, "insert and restore_all failed ($count != 5)");
};

if ($@) {
  warn "An exception occurred: $@\n";
}
