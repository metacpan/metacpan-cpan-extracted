#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/RDFS/List/Iterator.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/15/2007
# Revision:	$Id: Iterator.pm,v 1.11 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::RDFS::List::Iterator;

use strict;
use warnings;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /: (\d+)\.(\d+)/;

use ODO::Exception;
use ODO::Ontology::RDFS::Vocabulary;
use ODO::RDFS::List::PropertiesContainer;

__PACKAGE__->mk_accessors(qw/list next_item/);

sub new {
	my ($self, $list) = @_;
	return $self->Class::Base::new(list=> $list);
}


sub reset {
	my $self = shift;
	$self->next_item( $self->list() );
}


sub next {
	my $self = shift;
	
	# We test for erroneous conditions all through this method to be safe
	throw ODO::Exception::Runtime(error=> '$self->next_item() did not return an ODO::RDFS::List or ODO::Node object')
		unless(	   UNIVERSAL::isa($self->next_item(), 'ODO::RDFS::List')
				|| UNIVERSAL::isa($self->next_item(), 'ODO::Node'));
	
	return undef # rdf:nil was set last time through
		if(UNIVERSAL::isa($self->next_item(), 'ODO::Node'));

	my $item = $self->next_item()->properties()->first();
	throw ODO::Exception::Runtime(error=> '$self->next_item()->properties->first() did not return an ARRAY reference')
		unless(UNIVERSAL::isa($item, 'ARRAY'));
	
	throw ODO::Exception::Runtime(error=> 'ARRAY from $self->next_item()->properties->first() did not have exactly 1 element: ' . scalar(@{ $item }) . ' elements returned')
		unless(scalar(@{ $item }) == 1);
	
	$item = $item->[0];
	
	my $rest = $self->next_item()->properties()->rest();
	throw ODO::Exception::Runtime(error=> '$self->next_item()->properties()->rest() did not return an ARRAY reference')
		unless(UNIVERSAL::isa($rest, 'ARRAY'));

	throw ODO::Exception::Runtime(error=> 'ARRAY from $self->next_item()->properties->rest() did not have exactly 1 element: ' . scalar(@{$rest}) . ' elements returned')
		unless(scalar(@{ $rest }) == 1);

	$rest = $rest->[0];
	
	# If the rest of the list is just a pointer to the URI rdf:nil which is an instance of ODO::RDFS::List, spare
	# the object creation and set the next item as that ODO::Node object
	if($rest->subject()->equal($ODO::Ontology::RDFS::Vocabulary::nil)) {
		$self->next_item($rest->subject());
	}
	else {
		
		# The rdf:rest of a list with elements remaining is itself an ODO::RDFS::List object
		my $l = ODO::RDFS::List->new($rest->subject(), $self->list()->graph());
		throw ODO::Exception::Runtime(error=> 'Could not create ODO::RDFS::List object from RDFS::Properties::rest object')	
			unless(UNIVERSAL::isa($l, 'ODO::RDFS::List'));
		
		$self->next_item($l);
	}
	
	return $item->subject();
}


sub init {
	my ($self, $config) = @_;

	throw ODO::Exception::Parameter::Invalid(error=> 'Parameter is not of type RDFS:List')
		unless(UNIVERSAL::isa($config->{'list'}, 'ODO::RDFS::List'));
	
	$self->list( $config->{'list'} );
	$self->next_item( $config->{'list'} );

	return $self;
}

1;

__END__
