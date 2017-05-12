# $Id: Association.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $

package Myco::Base::Association;

use base qw(Myco::Base::Common Class::Tangram);

our $schema = {
	       abstract => 1,
	       table => 'Association',
	       fields => {},
	      };

Class::Tangram::import_schema("Myco::Base::Association");

1;
