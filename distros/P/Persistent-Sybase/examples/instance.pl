#!/usr/bin/perl -w
########################################################################
# File:     instance.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: instance.pl,v 1.1 2000/02/10 01:47:05 winters Exp winters $
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
use Persistent::Sybase;

########################################################################
#
# eval all of the persistent code to catch any exceptions
#
########################################################################

my $person;

eval {
  
  mkdir('data', 0777) unless -d 'data';
  
  ### allocate a persistent object ###
  $person = new Persistent::Sybase('dbi:Sybase:server=ENDODB',
				   'testdbo', 'test123', 'person');
  
  ### create the table if needed ###
  create_table($person->datastore());

  ### define attributes of the object ###
  $person->add_attribute('firstname', 'id',         'VarChar',  undef, 10);
  $person->add_attribute('lastname',  'id',         'VarChar',  undef, 20);
  $person->add_attribute('telnum',    'persistent', 'VarChar',  undef, 15);
  $person->add_attribute('bday',      'persistent', 'DateTime', undef);
  $person->add_attribute('age',       'transient',  'Number',   undef, 2);
  
  ########################################################################
  #
  # clear out data store to start tests
  #
  ########################################################################
  
  print "Deleting all objects\n";
  print "--------------------\n";
  $person->restore_all();
  while ($person->restore_next()) {
    $person->delete();
    print "Deleted:  ";  print_person($person);
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
  print "Inserted: ";  print_person($person);
  
  $person->firstname('Wilma');
  $person->lastname('Flintstone');
  $person->telnum('650-555-2222');
  $person->age(38);
  $person->insert();
  print "Inserted: ";  print_person($person);
  
  $person->firstname('Barney');
  $person->lastname('Rubble');
  $person->telnum('501-555-3333');
  $person->age(42);
  $person->insert();
  print "Inserted: ";  print_person($person);
  
  $person->firstname('Betty');
  $person->lastname('Rubble');
  $person->telnum('408-555-4444');
  $person->age(4);
  $person->bday('1970', '06', '12');
  $person->insert();
  print "Inserted: ";  print_person($person);
  
  $person->firstname('Shmu');
  $person->lastname('Moo');
  $person->telnum('415-555-5555');
  $person->age(25);
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
  $person->restore('Betty', 'Rubble');
  print "Restored: ";  print_person($person);
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
  print "Updated:  ";  print_person($person);
  print "\n";
  
  ########################################################################
  #
  # restoring some objects
  #
  ########################################################################
  
  print "Restore all the Flintstones in the 650 area code\n";
  print "------------------------------------------------\n";
  $person->restore_where("lastname = 'Flintstone' and telnum LIKE '650%'");
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
  $person->delete('Fred', 'Flintstone');
  print "Deleted:  ";  print_person($person);
  print "\n";
  
  ########################################################################
  #
  # restore an object, view its data, update its data, save it
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
  $person->restore_all('lastname desc, firstname, telnum');
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
  $new_person->add_attribute('firstname', 'id',         'VarChar',  undef, 10);
  $new_person->add_attribute('lastname',  'id',         'VarChar',  undef, 20);
  $new_person->add_attribute('telnum',    'persistent', 'VarChar',  undef, 15);
  $new_person->add_attribute('bday',      'persistent', 'DateTime', undef);
  $new_person->add_attribute('age',       'transient',  'Number',   undef, 2);
  
  $person->restore_all('lastname desc, firstname, telnum');
  while ($person->restore_next()) {
    $new_person->data($person->data());  ### copy the object data ###
    $new_person->insert();               ### save it ###
    print "Inserted: ";  print_person($new_person);
  }
  print "\n";
  
};

if ($EVAL_ERROR) {
  print "An error occurred: $EVAL_ERROR\n";
}

sub print_person {
  my $person = shift;
  
  printf("%-10s %-10s %15s %s %2s\n",
	 defined $person->firstname ? $person->firstname : 'undef',
	 defined $person->lastname ? $person->lastname : 'undef',
	 defined $person->telnum ? $person->telnum : 'undef',
	 defined $person->bday ? $person->bday : 'undef',
	 defined $person->age ? $person->age : 'undef');
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
