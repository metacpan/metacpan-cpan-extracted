#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/RDFS/PerlEntity.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/01/2005
# Revision:	$Id: PerlEntity.pm,v 1.13 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::RDFS::PerlEntity;

use strict;
use warnings;

use ODO::Exception;
use ODO::Ontology::RDFS::Vocabulary;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.13 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO::Ontology::PerlEntity/;

our $CLASS_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/classes/';
our $PROPERTY_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/properties/';

our $CLASS_IMPL_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/classes/impls';
our $PROPERTY_IMPL_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/properties/impls';
our $PROPERTY_ACC_IMPL_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/properties/accessors/impls';

sub new_instance {
	my ($self, $object_name, $resource) = @_;	

	my $uri = $object_name;
	# At this point, the passed in is a URI or an ODO::Node::Resource object
	throw ODO::Exception::Parameter::Invalid(error=> 'Resource parameter must be an ODO::Node::Resource or ODO::Node::Blank')
		unless(UNIVERSAL::isa($resource, 'ODO::Node::Resource'));
	
	$object_name = $object_name->uri()
		if(UNIVERSAL::isa($object_name, 'ODO::Node::Resource'));
	
	unless($self->__is_perl_package($object_name)) {
		$object_name = (    $self->ontology()->get_symtab_entry($CLASS_SYMTAB_URI, $object_name)
						|| $self->ontology()->get_symtab_entry($PROPERTY_SYMTAB_URI, $object_name) );        

		throw ODO::Exception::Runtime(error=> "Object: $uri does not have method 'new'")
			unless($object_name);
	}
	return $object_name->new($resource, $self->ontology()->graph(), @_);
}


sub find_instances {
	my ($self, $object_name) = @_;

	my $uri = $object_name;
	
	unless($self->__is_perl_package($object_name)) {
		$object_name = (   $self->ontology()->get_symtab_entry($CLASS_SYMTAB_URI, $object_name) 
						|| $self->ontology()->get_symtab_entry($PROPERTY_SYMTAB_URI, $object_name) );

		throw ODO::Exception::Runtime(error=> "Object: $uri does not have method 'new'")
			unless($object_name);
	}

	throw ODO::Exception::Runtime(error=> "$object_name does not have a query string")
		unless($object_name->queryString());
	
	my $rdf_map = "rdf for <${ODO::Ontology::RDFS::Vocabulary::RDF}>";
	my $rdfs_map = "rdfs for <${ODO::Ontology::RDFS::Vocabulary::RDFS}>";
	
	my $qs_rdql = 'SELECT ?stmt WHERE ' . $object_name->queryString() . " USING $rdf_map, $rdfs_map";
	
	my $results = $self->ontology()->graph()->query( $qs_rdql )->results();
	
	throw ODO::Exception::Runtime(error=> "Error querying for the object: $object_name")
		unless($results);
	
	my $objects = [];
	
	while(@{ $results }) {
		my $r = shift @{ $results };
		push @{ $objects }, $object_name->new($r->subject(), $self->ontology()->graph());
	}

	return (wantarray) ? @{ $objects } : $objects;
}


sub __find_class_instances {
	my $self = shift;
	return $self->__find_instances(@_);
}


sub __find_property_instances {
	my $self = shift;
	return $self->__find_instances(@_);
}


sub __can_as {
	my ($self, $uri, $package) = @_;

	return undef
		unless($self->($package));

	return 1;	
}


sub init {
	my ($self, $config) = @_;
	return $self->SUPER::init($config);
}

1;

__END__
