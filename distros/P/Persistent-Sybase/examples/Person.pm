########################################################################
# RCS:      $Id: Person.pm,v 1.1 2000/02/10 01:47:05 winters Exp winters $
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
use Persistent::Sybase;
@ISA = qw(Persistent::Sybase);

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
  $this->add_attribute('firstname', 'id',         'VarChar',  undef, 10);
  $this->add_attribute('lastname',  'id',         'VarChar',  undef, 20);
  $this->add_attribute('telnum',    'persistent', 'VarChar',  undef, 15);
  $this->add_attribute('bday',      'persistent', 'DateTime');
  $this->add_attribute('age',       'transient',  'Number',   undef, 2);
}

########################################################################
# Methods
########################################################################

sub print {
  my $this = shift;

  printf("%-10s %-10s %15s %s %2s\n",
	 defined $this->firstname ? $this->firstname : 'undef',
	 defined $this->lastname ? $this->lastname : 'undef',
	 defined $this->telnum ? $this->telnum : 'undef',
	 defined $this->bday ? $this->bday : 'undef',
	 defined $this->age ? $this->age : 'undef');
}

### end of library ###
1;
__END__
