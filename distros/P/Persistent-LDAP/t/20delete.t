########################################################################
# File:     20delete.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 20delete.t,v 1.2 2000/02/08 03:09:42 winters Exp winters $
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

### skip the tests if no NS-SLAPD is running ###
if ($Config{SkipTests} eq 'Y') {
  print "1..0\n";
  exit;
}

print "1..1\n";

### eval all of the persistent code to catch any exceptions ###
eval {

  ### Test #1: Delete an object ###
  my $person = new_person(\%Config);
  my $count = $person->restore('dclark');
  $person->delete();
  $person = new_person(\%Config);
  $count = $person->restore_where('mail=*49ers.com');
  test(1, $count == 4, "restore and delete failed ($count != 4)");
};

if ($@) {
  warn "An exception occurred: $@\n";
}
