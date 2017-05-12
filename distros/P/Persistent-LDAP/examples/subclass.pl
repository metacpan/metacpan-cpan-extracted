#!/usr/bin/perl -w
########################################################################
# File:     subclass.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id$
#
# An example script that uses inheritance (a subclass) of a
# Persistent class.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use strict;

use English;
use Person;

########################################################################
#
# eval all of the persistent code to catch any exceptions
#
########################################################################

my $person;

eval {
  
  mkdir('data', 0777) unless -d 'data';
  
  ### allocate a persistent object ###
  $person =
    new Person('localhost', 389, 'cn=Directory Manager', 'test1234',
      'ou=Snow Movers Dept,ou=Engineering,o=Big Snow Organization,c=US');

  ########################################################################
  #
  # clear out data store to start tests
  #
  ########################################################################
  
  print "Deleting all objects\n";
  print "--------------------\n";
  $person->restore_all;
  while ($person->restore_next) {
    if ($person->uid ne 'admin') {
      $person->delete();
      print "Deleted:  ";  $person->print($person);
    }
  }
  print "\n";
  
  ########################################################################
  #
  # insert some objects
  #
  ########################################################################
  
  print "Inserting objects\n";
  print "-----------------\n";

  $person->clear();
  $person->uid('fflintstone');
  $person->userpassword('fred123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Fred');
  $person->sn('Flintstone');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('fflintstone@bigsnow.org');
  $person->telephonenumber('650-555-1111');
  $person->temp('junk1');
  $person->insert();
  print "Inserted: ";  $person->print($person);
  
  $person->clear();
  $person->uid('wflintstone');
  $person->userpassword('wilma123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Wilma');
  $person->sn('Flintstone');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('wflintstone@bigsnow.org');
  $person->telephonenumber('650-555-2222');
  $person->temp('junk2');
  $person->insert();
  print "Inserted: ";  $person->print($person);
  
  $person->clear();
  $person->uid('brubble');
  $person->userpassword('barney123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Barney');
  $person->sn('Rubble');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('brubble@bigsnow.org');
  $person->telephonenumber('501-555-3333');
  $person->insert();
  print "Inserted: ";  $person->print($person);

  $person->clear();
  $person->uid('berubble');
  $person->userpassword('betty123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Betty');
  $person->sn('Rubble');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('berubble@bigsnow.org');
  $person->telephonenumber('408-555-4444');
  $person->insert();
  print "Inserted: ";  $person->print($person);

  $person->clear();
  $person->uid('smoo');
  $person->userpassword('shmu123');
  $person->objectclass(qw(top person organizationalPerson inetOrgPerson));
  $person->givenname('Shmu');
  $person->sn('Moo');
  $person->cn($person->givenname . ' ' . $person->sn);
  $person->mail('smoo@bigsnow.org');
  $person->telephonenumber('415-555-5555');
  $person->temp('junk3');
  $person->insert();
  print "Inserted: ";  $person->print($person);
  
  print "\n";
  
  ########################################################################
  #
  # restore all objects
  #
  ########################################################################
  
  print "Restoring all objects\n";
  print "---------------------\n";
  $person->restore_all();
  while ($person->restore_next()) {
    print "Restored: ";  $person->print($person);
  }
  print "\n";
  
  ########################################################################
  #
  # restore a single object
  #
  ########################################################################
  
  print "Restoring a single object\n";
  print "-------------------------\n";
  $person->clear();
  $person->restore('berubble');
  print "Restored: ";  $person->print($person);
  print "\n";
  
  ########################################################################
  #
  # update an object
  #
  ########################################################################
  
  print "Updating an object\n";
  print "------------------\n";
  $person->sn('Shmu');
  $person->telephonenumber('415-555-5555');
  $person->update();
  print "Updated ";  $person->print_full($person);
  print "\n";
  
  ########################################################################
  #
  # restoring some objects
  #
  ########################################################################
  
  print "Restore all the Flintstones in the 650 area code\n";
  print "------------------------------------------------\n";
  $person->restore_where('& (sn=Flintstone)(telephonenumber=650*)');
  while ($person->restore_next()) {
    print "Restored: ";  $person->print($person);
  }
  print "\n";
  
  ########################################################################
  #
  # deleting an object
  #
  ########################################################################
  
  print "Deleting an object\n";
  print "------------------\n";
  $person->delete('fflintstone');
  print "Deleted:  ";  $person->print($person);
  print "\n";
  
  ########################################################################
  #
  # restore an object, view its data, update its data, save it
  #
  ########################################################################
  
  print "Restoring, viewing, updating, and saving an object\n";
  print "--------------------------------------------------\n";
  $person->restore('wflintstone');
  print "Data:\n";
  my $href = $person->data();
  print "href = $href\n";
  foreach my $key (keys %$href) {
    printf("key = %s, value = %s\n",
	   defined $key ? $key : 'undef',
	   defined $href->{$key} ? $href->{$key} : 'undef');
  }
  
  print "New Data:\n";
  $href = $person->data({givenname => 'Marge', sn => 'Simpson'});
  $person->mail('marge@bigsnow.org');
  print "href = $href\n";
  foreach my $key (keys %$href) {
    printf("key = %s, value = %s\n",
	   defined $key ? $key : 'undef',
	   defined $href->{$key} ? $href->{$key} : 'undef');
  }
  
  $person->save();
  print "\n";
  
  ########################################################################
  #
  # clearing an object
  #
  ########################################################################
  
  print "Clearing an object\n";
  print "------------------\n";
  print "Before:   ";  $person->print($person);
  $person->clear();
  print "After:    ";  $person->print($person);
  print "\n";
  
  ########################################################################
  #
  # restore all objects
  #
  ########################################################################

  print "Restoring all objects\n";
  print "---------------------\n";
  $person->restore_all('sn desc, givenname, telephonenumber');
  while ($person->restore_next()) {
    print "Restored: ";  $person->print($person);
  }
  print "\n";

};

if ($EVAL_ERROR) {
  print "An error occurred: $EVAL_ERROR\n";
}
