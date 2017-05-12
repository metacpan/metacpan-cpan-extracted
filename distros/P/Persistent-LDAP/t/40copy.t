########################################################################
# File:     40copy.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 40copy.t,v 1.2 2000/02/08 03:09:42 winters Exp winters $
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

### skip the tests if no NS-SLAPD is running ###
if ($Config{SkipTests} eq 'Y') {
  print "1..0\n";
  exit;
}

print "1..2\n";

### eval all of the persistent code to catch any exceptions ###
eval {

  ### Test #1 and #2: Copy objects to new data store ###
  my $person = new_person(\%Config);
  my $person2 = new_person(\%Config, 'File');
  my $count = $person->restore_where('mail=*49ers.com');
  while ($person->restore_next()) {
    $person2->uid($person->uid);
    $person2->givenname($person->givenname);
    $person2->sn($person->sn);
    $person2->mail($person->mail);
    $person2->telephonenumber($person->telephonenumber);
    $person2->insert;
  }
  $person = new_person(\%Config);
  $person2 = new_person(\%Config, 'File');
  $count = $person->restore_where('mail=*49ers.com', "uid");
  my $count2 = $person2->restore_where('mail =~ /49ers.com$/', "uid");
  test(1, $count == $count2, "copy failed ($count != $count2)");
  $person->restore_next();
  $person2->restore_next();
  test(2, $person->uid eq $person2->uid && $person->sn eq $person2->sn,
       sprintf("copy failed (%s ne %s || %s ne %s)",
	       $person->uid, $person2->uid, $person->sn, $person2->sn));
};

if ($@) {
  warn "An exception occurred: $@\n";
}
