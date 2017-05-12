#!/usr/bin/perl -w
########################################################################
# File:     netscape_people.pl
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id$
#
# A script that queries a LDAP directory for all people as defined
# by the Netscape suite of servers.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use strict;

use Persistent::LDAP;
use English;  # import readable variable names like $EVAL_ERROR

eval {  ### in case an exception is thrown ###

  ### allocate a persistent object ###
  my $person =
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

  ### query the datastore for some objects ###
  $person->restore_where('& (objectclass=person)(mail=*bigsnow.org)', 'cn');
  while ($person->restore_next()) {
    print_person($person);
  }
};

if ($EVAL_ERROR) {  ### catch those exceptions! ###
  print "An error occurred: $EVAL_ERROR\n";
}

### formats and prints the attributes of a person ###
sub print_person {
  my $person = shift;

  print "Person\n";
  print "------\n";
  foreach my $attr (qw(uid userpassword objectclass
		       givenname sn cn mail telephonenumber)) {
    printf "$attr = %s\n", join(', ', $person->$attr());
  }
  print "\n";
}
