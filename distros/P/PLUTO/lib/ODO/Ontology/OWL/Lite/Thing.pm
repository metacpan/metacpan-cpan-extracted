#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Lite/Thing.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/27/2005
# Revision:	$Id: Thing.pm,v 1.3 2010-02-17 17:17:09 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Lite::Thing;

# Ultimate ancestor class for OWL classes.

use strict;
use warnings;

use Class::ISA;

use ODO::Node;
use ODO::Exception;
use ODO::Query::Simple::Parser;
use ODO::Ontology::RDFS::Vocabulary;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO/;

our @ISA;

our @METHODS = qw/graph subject propertyContainerName properties/;

__PACKAGE__->mk_accessors(@METHODS);
__PACKAGE__->mk_ro_accessors(qw/min_cardinality max_cardinality propertyURIMap/);


sub value {
	my $self = shift;
	
	throw ODO::Exception::Runtime(error=> 'Subject is not an ODO::Node object')
		unless($self->subject()->isa('ODO::Node'));
	
	return $self->subject()->value();
}


sub isRequiredProperty {
	my ($self, $propertyPackageName) = @_;
	my $minCardinality = $self->minCardinality($propertyPackageName);
	return ($minCardinality) ? 1 : 0;
}


sub minCardinality {
	my ($self, $propertyPackageName) = @_;
	
	my $minCardinalityHash = $self->{'min_cardinality'};
	
	if(exists($minCardinalityHash->{$propertyPackageName})) {
		return $minCardinalityHash->{$propertyPackageName};
	}
	
	return undef;
}

sub setMinCardinality {
	my ($self, $propertyPackageName, $value) = @_;
	
	my $minCardinalityHash = $self->{'min_cardinality'};
	$minCardinalityHash->{ $propertyPackageName } = $value;	
}


sub maxCardinality {
	my ($self, $propertyPackageName) = @_;
	
	my $maxCardinalityHash = $self->{'max_cardinality'};

	if(exists($maxCardinalityHash->{$propertyPackageName})) {
		return $maxCardinalityHash->{$propertyPackageName};
	}
	
	return undef;
}

sub setMaxCardinality {
	my ($self, $propertyPackageName, $value) = @_;
	
	my $maxCardinalityHash = $self->{'max_cardinality'};
	$maxCardinalityHash->{ $propertyPackageName } = $value;	
}


sub validateMinCardinality {
	my ($self, $propertyPackageName) = @_;

	my $minCardinality = $self->minCardinality($propertyPackageName);
	
	return 1 # Trivially validates if owl:minCardinality is not specified
		unless(defined($minCardinality));
		
	my $propertyInstances = $self->getPropertyFromGraph($propertyPackageName);
	my $numPropertyInstances = scalar(@{ $propertyInstances });
	
	if($minCardinality == 0) {
		# Do nothing, it is optional
	}
	
	if(   $minCardinality == 1
	   && $propertyInstances == 0) {
		throw ODO::Ontology::Evaluation(error=> "$propertyPackageName: minCardinality is restricted to 1 property, one instance must be present");
	}
	
	return $propertyInstances;
}


sub validateMaxCardinality {
	my ($self, $propertyPackageName) = @_;

	my $maxCardinality = $self->maxCardinality($propertyPackageName);
	
	return 1 # Trivially validates if owl:maxCardinality is not specified
		unless(defined($maxCardinality));

	my $propertyInstances = $self->getPropertyFromGraph($propertyPackageName);
	my $numPropertyInstances = scalar(@{ $propertyInstances });

	if(   $maxCardinality == 1
	   && $numPropertyInstances > 1) {
		throw ODO::Ontology::Evaluation(error=> "$propertyPackageName: maxCardinality is restricted to 1 property");
	}

	if(   $maxCardinality == 0
	   && $numPropertyInstances > 0) {
		throw ODO::Ontology::Evaluation(error=> "$propertyPackageName: maxCardinality is restricted to 0");
	}

	
	my $minCardinality = $self->minCardinality($propertyPackageName);
	
	$minCardinality = 0 # If owl:minCardinality isn't specified then make it 0 (optional)
		unless(defined($minCardinality));
	
	if(   $maxCardinality == 1
	   && $maxCardinality == $minCardinality
	   && $numPropertyInstances != 1) {
		throw ODO::Ontology::Evaluation(error=> "$propertyPackageName: Property must exist exactly once");
	}
	
	if(   $maxCardinality == 0
	   && $maxCardinality == $minCardinality
	   && $numPropertyInstances > 0) {
		throw ODO::Ontology::Evaluation(error=> "$propertyPackageName: Property can not exist");
	}
	
	return $propertyInstances;
}


sub canAddProperty {
	my ($self, $propertyPackageName) = @_;

	my $propertyInstances = $self->getPropertyFromGraph($propertyPackageName);
	my $numPropertyInstances = scalar(@{ $propertyInstances });


	my $minCardinality = $self->minCardinality($propertyPackageName);
	$minCardinality = 0
		unless(defined($minCardinality));
	
	my $maxCardinality = $self->maxCardinality($propertyPackageName);
	
	if(   defined($maxCardinality)
	   && $numPropertyInstances + 1 > $maxCardinality) {
		return 0;
	}
	elsif($numPropertyInstances + 1 >= $minCardinality) {
		return 1;
	}
	else {
		# FIXME: Add more conditionals here?
	}
}


sub isOfType {
	my ($self, $classPackageName) = @_;
	
	return 1
		if(UNIVERSAL::isa($self, $classPackageName));
	
	my $myURI = $self->subject()->value();
	my $rdfType = $ODO::Ontology::RDFS::Vocabulary::type;
	my $uri = $classPackageName->objectURI();
		
	my $typeQuery = "SELECT ?stmt WHERE (<$myURI>, <$rdfType>, <$uri>)";
	
	my $results = $self->issueQuery($typeQuery);

	return (scalar(@{ $results }) > 0) ? 1 : 0;
}


=item query( )

=cut

sub query {
	my $self = shift;
	
	throw ODO::Exception::Runtime(error=> 'Missing query string')
		unless($self->queryString());
	
	my $rdf_map = "rdf for <${ODO::Ontology::RDFS::Vocabulary::RDF}>";
	my $rdfs_map = "rdfs for <${ODO::Ontology::RDFS::Vocabulary::RDFS}>";
	
	my $qs_rdql = 'SELECT ?stmt WHERE ' . $self->queryString() . " USING $rdf_map, $rdfs_map";
			
	my $results = $self->issueQuery( $qs_rdql );
	
	my $objects = [];
	while(@{ $results }) {
	
		my $r = shift @{ $results };
		my $object = ref $self;
		push @{ $objects }, $object->new($r->subject(), $self->graph());
	}
	
	return (wantarray) ? @{ $objects } : $objects;
}


sub getPropertyFromGraph {
	my ($self, $propertyPackageName) = @_;
	
	throw ODO::Exception::Parameter::Missing(error=> 'Missing property package name')
		unless($propertyPackageName);
	
	# Only Resources can have properties
	throw ODO::Exception::Runtime(error=> 'Subject is not a ODO::Graph::Node::Resource')
		unless($self->subject()->isa('ODO::Graph::Node::Resource'));
	
	throw ODO::Exception::Runtime(error=> 'Missing ODO::Graph object')
		unless($self->graph());
	
	my $propertyQueryString = $propertyPackageName->queryString();

	throw ODO::Exception::Runtime(error=> 'Missing property query string')
		unless($propertyQueryString);
	
	my $propertyTripleMatch = ODO::Query::Simple::Parser->parse($propertyQueryString);
	
	
	# FIXME: Probably good enough for now
	$propertyTripleMatch = $propertyTripleMatch->[0];

	# Create a triple match that can get all of _THIS_ object's
	# instances of the specific property.
	$propertyTripleMatch->subject($self->subject());
	$propertyTripleMatch->predicate($propertyTripleMatch->object());
	$propertyTripleMatch->object( $ODO::Node::ANY );

	my $results = $self->graph()->query($propertyTripleMatch)->results();
	
	my $objects = [];

	while(@{ $results }) {
		my $r = shift @{ $results };
		push @{ $objects }, $propertyPackageName->new($r->object(), $self->graph());
	}
	
	return (wantarray) ? @{ $objects } : $objects;	
}


sub issueQuery {
	my ($self, $query) = @_;
	my $result_set = $self->graph()->query($query);
	my $results = $result_set->results();
	return (wantarray) ? @{ $results } : $results;
}


sub init {
	my ($self, $config) = @_;

	$self->params($config, @METHODS);
	
	$self->{'propertyURIMap'} = {};
	
	# Hashes that will store property cardinality information
	$self->{'min_cardinality'} = {};
	$self->{'max_cardinality'} = {};
	
	# FIXME: This is an instance and hence is an Individual of a class
	unshift @ISA, 'ODO::Ontology::OWL::Lite::Individual';
	
	return $self;
}


package ODO::Ontology::OWL::Lite::Thing::PropertiesContainer;


package ODO::Ontology::OWL::Lite::NoThing;

use vars qw( @ISA );

@ISA = ( );

package ODO::Ontology::OWL::Lite::NoThing::PropertiesContainer;

use vars qw( @ISA );

@ISA = ( );


package ODO::Ontology::OWL::Lite::Individual;

# Objects are owl:Individuals iff they are instantiated types

package ODO::Ontology::OWL::Lite::ObjectProperty;


package ODO::Ontology::OWL::Lite::DatatypeProperty;


package ODO::Ontology::OWL::Lite::AnnotationProperty;


1;

__END__
