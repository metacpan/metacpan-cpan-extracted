########################################################################
# File:     10insert.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 10insert.t,v 1.2 2000/02/08 03:09:42 winters Exp winters $
#
# This script tests the insert and restore_where methods.
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

  ### Test #1: Insert 5 objects ###
  my $person = new_person(\%Config);

  $person->uid('syoung');
  $person->userpassword('steve123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Steve');
  $person->sn('Young');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('syoung@49ers.com');
  $person->telephonenumber('650-555-1111');
  $person->insert();

  $person->uid('jmontana');
  $person->userpassword('joe123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Joe');
  $person->sn('Montana');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('jmontana@ex49ers.com');
  $person->telephonenumber('650-555-2222');
  $person->insert();

  $person->uid('jrice');
  $person->userpassword('jerry123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Jerry');
  $person->sn('Rice');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('jrice@49ers.com');
  $person->telephonenumber('650-555-3333');
  $person->insert();

  $person->uid('dclark');
  $person->userpassword('dwight123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Dwight');
  $person->sn('Clark');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('dclark@ex49ers.com');
  $person->telephonenumber('650-555-4444');
  $person->insert();

  $person->uid('rcraig');
  $person->userpassword('roger123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Roger');
  $person->sn('Craig');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('rcraig@ex49ers.com');
  $person->telephonenumber('650-555-5555');
  $person->insert();

  $person = new_person(\%Config);
  my $count = $person->restore_where('mail=*49ers.com');
  test(1, $count == 5, "insert and restore_where failed ($count != 5)");
};

if ($@) {
  warn "An exception occurred: $@\n";
}
