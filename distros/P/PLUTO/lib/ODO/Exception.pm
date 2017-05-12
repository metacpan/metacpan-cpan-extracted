#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Exception.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  06/24/2005
# Revision:	$Id: Exception.pm,v 1.2 2009-11-25 17:46:52 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

# For try { ... } catch { ... } syntactic sugar
use Error qw(:try);

package ODO::Exception;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

$SIG{__DIE__} = sub { 
	if(!UNIVERSAL::isa($_[0], 'Exception::Class')) { 
		throw Exception::Class::Base(error => join '', @_); 
	}
};

use Exception::Class(

	ODO::Exception::Module=>
		{
			description=> '',
		},

	ODO::Exception::Parameter=>
		{
			description=> '',
		},
	ODO::Exception::Parameter::Missing=>
		{
			description=> '',
			isa=> 'ODO::Exception::Parameter',
		},
	ODO::Exception::Parameter::Invalid=>
		{
			description=> '',
			isa=> 'ODO::Exception::Parameter',
		},
		
	ODO::Exception::File=>
		{
			description=> '',
		},
	ODO::Exception::File::Missing=>
		{
			description=> '',
			isa=> 'ODO::Exception::File',
		},
	ODO::Exception::File::Corrupt=>
		{
			description=> '',
			isa=> 'ODO::Exception::File',
		},
	
	ODO::Exception::Runtime=>
		{
			description=> '',
		},
	
	# Graph
	
	# RDF Parser
	ODO::Exception::RDF=>
		{
			description=> '',
		},
	ODO::Exception::RDF::Parse=>
		{
			description=> '',
			isa=> 'ODO::Exception::RDF',
		},
		
	# Database
	ODO::Exception::DB=>
		{
			description=> '',
		},
	ODO::Exception::DB::NotImplemented=>
		{
			description=> '',
			isa=> 'ODO::Exception::DB',
		},
	
	# Query
	ODO::Exception::Query=>
		{
			description=> '',
		},

	ODO::Exception::Query::Parse=>
		{
			description=> '',
			isa=> 'ODO::Exception::Query',
		},
	
	ODO::Exception::Query::RDQL=>
		{
			description=> '',
			isa=> 'ODO::Exception::Query',
		},
	ODO::Exception::Query::RDQL::Parse=>
		{
			description=> '',
			isa=> 'ODO::Exception::Query::RDQL',
		},
	ODO::Exception::Query::RDQL::Execution=>
		{
			description=> '',
			isa=> 'ODO::Exception::Query::RDQL',
		},

	# Ontology Exceptions
	ODO::Exception::Ontology=>
		{
			description=> '',
		},
	ODO::Exception::Ontology::TemplateParse=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology',
		},
	ODO::Exception::Ontology::Evaluation=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology',
		},
	ODO::Exception::Ontology::DuplicateClass=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology',
		},
	ODO::Exception::Ontology::DuplicateProperty=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology',
		},
	ODO::Exception::Ontology::MissingClass=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology',
		},
	ODO::Exception::Ontology::MissingProperty=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology',
		},

	ODO::Exception::Ontology::OWL=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology',
		},
	ODO::Exception::Ontology::OWL::Parse=>
		{
			description=> '',
			isa=> 'ODO::Exception::Ontology::OWL',
		},
	
);


Exception::Class::Base->Trace(1);

# XXX: Hack according to perldoc Exception::Class for syntactic sugar
push @Exception::Class::Base::ISA, 'Error'
	unless Exception::Class::Base->isa('Error');

use strict;
use warnings;

1;

__END__
