#!/usr/bin/perl -w
########################################################################
# File:     subclass.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: subclass.pl,v 1.1 2000/02/10 01:47:05 winters Exp winters $
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
  $person = new Person("dbi:Sybase:server=ENDODB", 'testdbo', 'test123', "person");
  
  ### create the table if needed ###
  create_table($person->datastore());

  ########################################################################
  #
  # clear out datastore to start tests
  #
  ########################################################################
  
  print "Deleting all objects\n";
  print "--------------------\n";
  $person->restore_all();
  $person->restore_all();
  while ($person->restore_next()) {
    $person->delete();
    print "Deleted: ";  $person->print();
  }
  print "\n";
  
  ########################################################################
  #
  # insert some objects
  #
  ########################################################################
  
  print "Inserting objects\n";
  print "-----------------\n";
  $person->firstname('Fred');
  $person->lastname('Flintstone');
  $person->telnum('650-555-1111');
  $person->age(45);
  $person->bday('1954-01-23 22:09:54');
  $person->insert();
  print "Inserted: ";  $person->print();
  
  $person->firstname('Wilma');
  $person->lastname('Flintstone');
  $person->telnum('650-555-2222');
  $person->age(38);
  $person->insert();
  print "Inserted: ";  $person->print();
  
  $person->firstname('Barney');
  $person->lastname('Rubble');
  $person->telnum('501-555-3333');
  $person->age(42);
  $person->insert();
  print "Inserted: ";  $person->print();
  
  $person->firstname('Betty');
  $person->lastname('Rubble');
  $person->telnum('408-555-4444');
  $person->age(4);
  $person->bday('1970', '06', '12');
  $person->insert();
  print "Inserted: ";  $person->print();
  
  $person->firstname('Shmu');
  $person->lastname('Moo');
  $person->telnum('415-555-5555');
  $person->age(25);
  $person->insert();
  print "Inserted: ";  $person->print();
  
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
    print "Restored: ";  $person->print();
  }
  print "\n";
  
  ########################################################################
  #
  # restore a single object
  #
  ########################################################################
  
  print "Restoring a single object\n";
  print "-------------------------\n";
  $person->restore('Betty', 'Rubble');
  print "Restored: ";  $person->print();
  print "\n";
  
  ########################################################################
  #
  # update an object
  #
  ########################################################################
  
  print "Updating an object\n";
  print "------------------\n";
  $person->lastname('Shmu');
  $person->telnum('415-555-5555');
  $person->update();
  print "Updated: ";  $person->print();
  print "\n";
  
  ########################################################################
  #
  # restoring some objects
  #
  ########################################################################
  
  print "Restore all the Flintstones in the 650 area code\n";
  print "------------------------------------------------\n";
  my $lastname = "Flintstone";
  $person->restore_where(sprintf("lastname = %s and telnum LIKE '650%%'",
				 $person->quote($lastname)));
  while ($person->restore_next()) {
    print "Restored: ";  $person->print();
  }
  print "\n";
  
  ########################################################################
  #
  # deleting an object
  #
  ########################################################################
  
  print "Deleting an object\n";
  print "------------------\n";
  $person->delete('Fred', 'Flintstone');
  print "Deleted: ";  $person->print();
  print "\n";
  
  ########################################################################
  #
  # restore an object, views its data, update its data, save it
  #
  ########################################################################
  
  print "Restoring, viewing, updating, and saving an object\n";
  print "--------------------------------------------------\n";
  $person->restore('Wilma', 'Flintstone');
  print "Data:\n";
  my $href = $person->data();
  print "href = $href\n";
  foreach my $key (keys %$href) {
    printf("key = %s, value = %s\n",
	   defined $key ? $key : 'undef',
	   defined $href->{$key} ? $href->{$key} : 'undef');
  }
  
  print "New Data:\n";
  $href = $person->data({firstname => 'Marge', lastname => 'Simpson'});
  $person->bday('1968-11-09 11:09:03');
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
  print "Before: ";  $person->print();
  $person->clear();
  print "After: ";  $person->print();
  print "\n";
  
  ########################################################################
  #
  # restore all objects
  #
  ########################################################################
  
  print "Restoring all objects\n";
  print "---------------------\n";
  $person->restore_all('lastname desc, firstname, telnum');
  while ($person->restore_next()) {
    print "Restored: ";  $person->print();
  }
  print "\n";
  
};

if ($EVAL_ERROR) {
  print "An error occurred: $EVAL_ERROR\n";
}

sub create_table {
  my $dbh = shift;

  ### query data dictionary for the existence of the table ###
  my $sth =
    $dbh->prepare("SELECT name FROM sysobjects " .
		  "WHERE name = 'person' AND type ='U'")
      or die "can't prepare statement: $DBI::errstr";
  my $rc = $sth->execute() or die "Can't execute statement: $DBI::errstr";
  my $count = 0;
  while ($sth->fetchrow_array()) { $count++ };

  ### create the table if it does not exist ###
  if ($count != 1) {
    $dbh->do(qq(
		CREATE TABLE person (
				     firstname VARCHAR(10) NOT NULL,
				     lastname  VARCHAR(20) NOT NULL,
				     telnum    VARCHAR(15) NULL,
				     bday      DATETIME    NULL
				    )
	       ))  or warn $dbh->errstr;
  }
}
