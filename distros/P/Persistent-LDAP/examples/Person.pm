########################################################################
# RCS:      $Id: Person.pm,v 1.1 1999/08/07 05:59:49 winters Exp winters $
# File:     Person.pm
# Author:   David Winters <winters@bigsnow.org>
#
# An example of a subclass that uses a Persistent class.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
########################################################################

package Person;
require 5.004;

use strict;
use vars qw(@ISA);

### we are a subclass of an all-powerful Persistent class ###
use Persistent::LDAP;
@ISA = qw(Persistent::LDAP);

### we inherit new() from the superclass, and override initialize to
### set our instance data

########################################################################
# Function:    initialize
# Description: Initializes an object.
# Parameters:  @params = initialization parameters
# Returns:     None
########################################################################
sub initialize {
  my $this = shift;

  ### call any ancestor initialization methods ###
  $this->SUPER::initialize(@_);

  ### define all attributes of the object ###
  $this->add_attribute('uid',             'ID',         'String');
  $this->add_attribute('userpassword',    'Persistent', 'String');
  $this->add_attribute('objectclass',     'Persistent', 'String');
  $this->add_attribute('givenname',       'Persistent', 'String');
  $this->add_attribute('sn',              'Persistent', 'String');
  $this->add_attribute('cn',              'Persistent', 'String');
  $this->add_attribute('mail',            'Persistent', 'String');
  $this->add_attribute('telephonenumber', 'Persistent', 'String');
  $this->add_attribute('temp',            'Transient',  'String');
}

########################################################################
# Methods
########################################################################

sub print {
  my $this = shift;
  
  printf("%-10s %-15s %-12s %-23s %2s\n",
	 defined $this->givenname ? $this->givenname : 'undef',
	 defined $this->sn ? $this->sn : 'undef',
	 defined $this->telephonenumber ? $this->telephonenumber : 'undef',
	 defined $this->mail ? $this->mail : 'undef',
	 defined $this->temp ? $this->temp : 'undef');
}

### formats and prints all the attributes of a person ###
sub print_full {
  my $this = shift;

  print "Person:\n";
  foreach my $attr (qw(uid userpassword objectclass
		       givenname sn cn mail telephonenumber)) {
    printf "$attr = %s\n", join(', ', $this->$attr());
  }
  print "\n";
}

### end of library ###
1;
__END__
