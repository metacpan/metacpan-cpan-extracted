# $Id: Association.pm,v 1.1.1.1 2005/12/09 18:08:47 sommerb Exp $

package Myco::Association;

use base qw(Myco::Common Class::Tangram);

our $schema = {
	       abstract => 1,
	       table => 'association',
	       fields => {},
	      };

Class::Tangram::import_schema("Myco::Association");

1;
