#!/usr/bin/perl -w
########################################################################
# File:     instance.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id$
#
# An example script that uses an instantiation of a Persistent class.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use strict;

use English;
use Persistent::File;
use Persistent::LDAP;

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
    new Persistent::LDAP('localhost', 389,
			 'cn=Directory Manager', 'test1234',
      'ou=Snow Movers Dept,ou=Engineering,o=Big Snow Organization,c=US');

  ### declare attributes of the object ###
  $person->add_attribute('uid',             'ID',         'String');
  $person->add_attribute('userpassword',    'Persistent', 'String');
  $person->add_attribute('objectclass',     'Persistent', 'String');
  $person->add_attribute('givenname',       'Persistent', 'String');
  $person->add_attribute('sn',              'Persistent', 'String');
  $person->add_attribute('cn',              'Persistent', 'String');
  $person->add_attribute('mail',            'Persistent', 'String');
  $person->add_attribute('telephonenumber', 'Persistent', 'String');
  $person->add_attribute('temp',            'Transient',  'String');

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
      print "Deleted:  ";  print_person($person);
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
  print "Inserted: ";  print_person($person);
  
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
  print "Inserted: ";  print_person($person);
  
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
  print "Inserted: ";  print_person($person);

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
  print "Inserted: ";  print_person($person);

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
  print "Inserted: ";  print_person($person);
  
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
    print "Restored: ";  print_person($person);
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
  print "Restored: ";  print_person($person);
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
  print "Updated ";  print_full_person($person);
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
    print "Restored: ";  print_person($person);
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
  print "Deleted:  ";  print_person($person);
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
  print "Before:   ";  print_person($person);
  $person->clear();
  print "After:    ";  print_person($person);
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
    print "Restored: ";  print_person($person);
  }
  print "\n";
  
  ########################################################################
  #
  # save all objects to a new datastore
  #
  ########################################################################
  
  print "Saving all objects to a new datastore\n";
  print "-------------------------------------\n";

  ### remove the new datastore if it already exists ###
  unlink <data/people.txt*>;

  ### allocate new object and define attributes ###
  my $new_person = new Persistent::File('data/people.txt', "\t");

  ### declare attributes of the object ###
  $new_person->add_attribute('firstname',       'ID',         'String');
  $new_person->add_attribute('lastname',        'ID',         'String');
  $new_person->add_attribute('telnum',          'Persistent', 'String');
  $new_person->add_attribute('email',           'Persistent', 'String');

  ### copy the data, one object at a time ###
  $person->restore_all('telephonenumber, sn asc, givenname');
  while ($person->restore_next()) {

    ### copy the object data ###
    $new_person->firstname($person->givenname);
    $new_person->lastname($person->sn);
    $new_person->telnum($person->telephonenumber);
    $new_person->email($person->mail);

    ### save it ###
    $new_person->insert();
    print "Inserted: ";  print_person($person);
  }
  print "\n";
  
};

if ($EVAL_ERROR) {
  print "An error occurred: $EVAL_ERROR\n";
}

sub print_person {
  my $person = shift;
  
  printf("%-10s %-15s %-12s %-23s %2s\n",
	 defined $person->givenname ? $person->givenname : 'undef',
	 defined $person->sn ? $person->sn : 'undef',
	 defined $person->telephonenumber ? $person->telephonenumber : 'undef',
	 defined $person->mail ? $person->mail : 'undef',
	 defined $person->temp ? $person->temp : 'undef');
}

### formats and prints the attributes of a person ###
sub print_full_person {
  my $person = shift;

  print "Person:\n";
  foreach my $attr (qw(uid userpassword objectclass
		       givenname sn cn mail telephonenumber)) {
    printf "$attr = %s\n", join(', ', $person->$attr());
  }
  print "\n";
}
