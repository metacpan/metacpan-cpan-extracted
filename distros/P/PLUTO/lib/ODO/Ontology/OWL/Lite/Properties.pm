#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Lite/Properties.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  05/01/2005
# Revision:	$Id: Properties.pm,v 1.8 2010-03-09 17:57:59 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Lite::Properties;

use strict;
use warnings;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

use ODO::Exception;
use ODO::Node;
use ODO::Query::Simple;
use ODO::Ontology::OWL::Lite::Fragments;

use base qw/ODO/;

__PACKAGE__->mk_accessors(qw/graph/);
__PACKAGE__->mk_ro_accessors(qw/fragments object inverse_functional symmetric transitive annotation datatype functional/);


sub init {
	my ($self, $config) = @_;
	
	$self->params($config, qw/graph/);
	
	# The keys of these hashes are URIs and should be checked for existance before
	# adding an item to the hash.
	$self->{'object'} = {};
	$self->{'inverse_functional'} = {};
	$self->{'symmetric'} = {};
	$self->{'transitive'} = {};
	
	$self->{'annotation'} = {};
	$self->{'datatype'} = {};
	
	$self->{'functional'} = {};
	
	$self->{'fragments'} = ODO::Ontology::OWL::Lite::Fragments->new(graph=> $self->graph());
	
	$self->__make_property_objects();
	
	return $self;
}


sub __make_property_objects {
	my $self = shift;
	
	my $rawProperties = $self->fragments()->getObjectProperties();
	
	throw ODO::Exception::Runtime(error=> 'Could not get property fragment interface ODO::Ontology::OWL::Lite::Fragments::ObjectProperties')	
		unless($rawProperties->isa('ODO::Ontology::OWL::Lite::Fragments::ObjectProperties'));
	
	my $owlObjectProperty = $ODO::Ontology::OWL::Vocabulary::ObjectProperty->value();
	my $owlInverseFunctionalProperty = $ODO::Ontology::OWL::Vocabulary::InverseFunctionalProperty->value();
	my $owlTransitiveProperty = $ODO::Ontology::OWL::Vocabulary::TransitiveProperty->value();
	my $owlSymmetricProperty = $ODO::Ontology::OWL::Vocabulary::SymmetricProperty->value();
	
	
	foreach my $property (@{ $rawProperties }) {

		# Stop dereferencing
		my $propertyURI = $property->subject()->value();
		my $typeURI = $property->object()->value();
		
		
		if($typeURI eq $owlInverseFunctionalProperty) {
			$self->inverse_functional()->{ $propertyURI } = $property->subject();
		}
		elsif($typeURI eq $owlTransitiveProperty) {
			$self->transitive()->{ $propertyURI } = $property->subject();
		}
		elsif($typeURI eq $owlSymmetricProperty) {
			$self->symmetric()->{ $propertyURI } = $property->subject();			
		}
		
		# Just an ObjectProperty, but it could be an ObjectProperty with
		# a transitive, symmetric, inverse functional which will get detected
		# later
		$self->object()->{ $propertyURI } = $property->subject();
		
		if($self->fragments()->hasFunctionalProperty($propertyURI)) {
			$self->functional()->{ $propertyURI } = $property->subject();
		}		

		$self->__fill_property($self->object(), $property->subject());
	}
	

	# Datatype Properties
	my $rawDatatypes = $self->fragments()->getDatatypeProperties();
	foreach my $property (@{ $rawDatatypes }) {
	
		my $propertyURI = $property->subject()->value();
		
		$self->datatype()->{ $propertyURI } = $property->subject();

		if($self->fragments()->hasFunctionalProperty($propertyURI)) {
			$self->functional()->{ $propertyURI } = $property->subject();
		}
		
		$self->__fill_property($self->datatype(), $property->subject());
	}

	
	# Annotation
	my $rawAnnotationProperties = $self->fragments()->getAnnotationProperties();
	foreach my $property (@{ $rawAnnotationProperties }) {
	
		my $propertyURI = $property->subject()->value();
		$self->annotation()->{ $propertyURI } = $property->subject();
		
		$self->__fill_property($self->annotation(), $property->subject());
	}
}


sub __fill_property {
	my ($self, $repository, $object) = @_;
	
	my $objectURI = $object->value();
	
	#
	# Create a new hash for the data for this particular property. We 
	# take care to preserve the actual object node (which tells us if it is
	# a Resource node or a Blank node) from the original hash entry
	#
	my $dataItems = {};
	
	$dataItems->{'object'} = $repository->{ $object->value() };
	$repository->{ $objectURI } = $dataItems;
	
	# Domain
	$dataItems->{'domain'} = $self->fragments()->getPropertyDomain($objectURI);
	
	# Range
	my @TMP_range = map { $_->object()->value() } $self->fragments()->getPropertyRange($objectURI);
	$dataItems->{'range'} = \@TMP_range;
	
	
	# SubProperty
	my $subProperty = $self->__get_schema_data($objectURI, $ODO::Ontology::RDFS::Vocabulary::subPropertyOf);
	
	# Properties in OWL are all subProperties of rdfs:Property
	push @{ $subProperty }, $ODO::Ontology::RDFS::Vocabulary::Property;
	
	if(scalar(@{ $subProperty })) {
		$dataItems->{'inheritance'} = $subProperty;
	}
	
	
	# EquivalentProperty
	my $equivalentProperty = $self->__get_schema_data($objectURI, $ODO::Ontology::OWL::Vocabulary::equivalentProperty);
	if(scalar(@{ $equivalentProperty })) {
		$dataItems->{'equivalentProperty'} = $equivalentProperty;
	}		
	
	
	# InverseOf
	$dataItems->{'inverses'} = $self->__get_schema_data($objectURI, $ODO::Ontology::OWL::Vocabulary::inverseOf);
}


# TODO: Fix this so that it is documented better and factored out
# __get_schema_data( $schemaObject, $property )
sub __get_schema_data {

	my $self = shift;
	
	my $schemaObject = shift;
	my $property = shift;	
	$schemaObject = ODO::Node::Resource->new( $schemaObject )
		unless($schemaObject->isa('ODO::Node::Resource'));
		
	$property = ODO::Node::Resource->new( $property )
		unless($property->isa('ODO::Node::Resource'));
	
	my $query = ODO::Query::Simple->new($schemaObject, $property, undef);
	my @results = map { $_->object()->value() } @{ $self->graph()->query($query)->results() };
	return \@results;
}


1;

__END__
