########################################################################
# File:     30update.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 30update.t,v 1.2 2000/02/08 03:09:42 winters Exp winters $
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

### skip the tests if no NS-SLAPD is running ###
if ($Config{SkipTests} eq 'Y') {
  print "1..0\n";
  exit;
}

print "1..3\n";

### eval all of the persistent code to catch any exceptions ###
eval {

  ### Tests #1, #2, and #3: Update 2 objects ###
  my $person = new_person(\%Config);
  my $count = $person->restore_where('mail=*@49ers.com');
  test(1, $count == 2, "restore_where failed ($count != 2)");
  while ($person->restore_next()) {
    $person->telephonenumber('415-999-9999');
    $person->update();
  }
  $person = new_person(\%Config);
  $count = $person->restore_where('& (mail=*@49ers.com)(telephonenumber=415-999-9999)');
  test(2, $count == 2, "restore_where failed ($count != 2)");
  $person->restore_next();
  my $phone = $person->telephonenumber();
  test(3, $phone eq '415-999-9999', "update failed ($phone ne '415-999-9999')");
};

if ($@) {
  warn "An exception occurred: $@\n";
}
