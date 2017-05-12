# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Lite/Fragments.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/29/2005
# Revision:	$Id: Fragments.pm,v 1.60 2010-02-17 17:17:09 ubuntu Exp $
#
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Lite::Fragments;
use strict;
use warnings;

use ODO::RDFS::List;
use ODO::Exception;
use ODO::Graph::Simple;
use ODO::Ontology::RDFS;
use ODO::Ontology::OWL::Vocabulary;
use ODO::Ontology::RDFS::Vocabulary;
use ODO::Ontology::RDFS::List::Iterator;
use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.62 $ =~ /: (\d+)\.(\d+)/;

__PACKAGE__->mk_accessors(qw/graph/);

sub getClasses {
	my $self     = shift;
	my $rdfType  = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $owlClass = $ODO::Ontology::OWL::Vocabulary::Class->value();

	# Find the owl:Class objects first
	my $queryString = "SELECT ?stmt WHERE (?classID, <$rdfType>, <$owlClass>)";
	my $results     = $self->graph()->query($queryString)->results();
	my %classes_seen;

	# Ignore anonymous owl:Class
	my @tmp;
	foreach my $tmp_r ( @{$results} ) {
		#unless ( UNIVERSAL::isa( $tmp_r->subject(), 'ODO::Node::Blank' ) ) {
			$classes_seen{ $tmp_r->subject()->value } = 1;
			push @tmp, $tmp_r;
		#}
	}

	# get nodes that are subClassOf ... uris
	$rdfType = $ODO::Ontology::RDFS::Vocabulary::subClassOf->value();
	$queryString =
	  "SELECT ?classID, ?subClassOf WHERE (?classID, <$rdfType>, ?subClassOf)";
	$results = $self->graph()->query($queryString)->results();

	# Ignore anonymous owl:Class and classes already defined
	foreach my $tmp_r ( @{$results} ) {
		#print STDERR "bnode found ...\n" if UNIVERSAL::isa( $tmp_r->object(), 'ODO::Node::Blank' );
		unless ( 
		  #UNIVERSAL::isa( $tmp_r->object(), 'ODO::Node::Blank' ) and
		  not $classes_seen{ $tmp_r->object()->value } )
		{
			$classes_seen{ $tmp_r->object()->value } = 1;
			my $class = ODO::Statement->new(
						 $tmp_r->object()->isa('ODO::Node::Blank' ) ? $tmp_r->object() : ODO::Node::Resource->new( $tmp_r->object->value ),
						 ODO::Node::Resource->new(
									 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
						 ODO::Node::Resource->new('http://www.w3.org/2002/07/owl#Class')
			);
			push @tmp, $class;
		}
	}
	$results = \@tmp;
	return (wantarray) ? @{$results} : bless $results,
	  'ODO::Ontology::OWL::Lite::Fragments::Classes';
}

sub getClassIntersectionOf {
	my ( $self, $class ) = @_;
	my $classURI = $class;
	$classURI = $class->value()
	  if ( $class->isa( 'ODO::Node::Resource' ) );
	my $owlIntersectionOf = $ODO::Ontology::OWL::Vocabulary::intersectionOf->value();
	my $owlClass          = $ODO::Ontology::OWL::Vocabulary::Class->value();

	# Find the owl:Class objects first
	my $queryString  = "SELECT ?stmt WHERE (<$classURI>, <$owlIntersectionOf>, ?list)";
	my $classResults = $self->graph()->query($queryString)->results();
	my $classIntersection = {
							  classes      => [],
							  restrictions => [],
	};
	if ( scalar( @{$classResults} ) ) {
		my $list = ODO::RDFS::List->new( $classResults->[0]->object(), $self->graph() );
		my $listIter = ODO::Ontology::RDFS::List::Iterator->new($list);
		throw ODO::Exception::Runtime(
								   error => "Could not create iterator for ODO::RDFS::List" )
		  unless ( $listIter->isa( 'ODO::Ontology::RDFS::List::Iterator' ) );
		my $iterElement;
		while ( ( $iterElement = $listIter->next() ) ) {
			if ( $iterElement->isa( 'ODO::Node::Blank' ) ) {
				my $restriction = $self->getClassRestriction( $iterElement->value() );
				push @{ $classIntersection->{'restrictions'} }, $restriction;
			} else {
				push @{ $classIntersection->{'classes'} }, $iterElement->value();
			}
		}
	}
	return $classIntersection;
}

sub getClassUnionOf {
    my ( $self, $class ) = @_;
    my $classURI = $class;
    $classURI = $class->value()
      if ( $class->isa( 'ODO::Node::Resource' ) );
    my $owlUnionOf = $ODO::Ontology::OWL::Vocabulary::unionOf->value();
    my $owlClass          = $ODO::Ontology::OWL::Vocabulary::Class->value();

    # Find the owl:Class objects first
    my $queryString  = "SELECT ?stmt WHERE (<$classURI>, <$owlUnionOf>, ?list)";
    my $classResults = $self->graph()->query($queryString)->results();
    my $classUnion = {
                              classes      => [],
                              restrictions => [],
    };
    if ( scalar( @{$classResults} ) ) {
        my $list = ODO::RDFS::List->new( $classResults->[0]->object(), $self->graph() );
        my $listIter = ODO::Ontology::RDFS::List::Iterator->new($list);
        throw ODO::Exception::Runtime(
                                   error => "Could not create iterator for ODO::RDFS::List" )
          unless ( $listIter->isa( 'ODO::Ontology::RDFS::List::Iterator' ) );
        my $iterElement;
        while ( ( $iterElement = $listIter->next() ) ) {
            if ( $iterElement->isa( 'ODO::Node::Blank' ) ) {
                my $restriction = $self->getClassRestriction( $iterElement->value() );
                push @{ $classUnion->{'restrictions'} }, $restriction;
            } else {
                push @{ $classUnion->{'classes'} }, $iterElement->value();
            }
        }
    }
    return $classUnion;
}

sub getClassRestriction {
	my ( $self, $restrictionURI ) = @_;
	my $restriction = { restrictionURI => $restrictionURI };

	#
	# Generic restriction processing
	#
	my $rdfType        = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $owlRestriction = $ODO::Ontology::OWL::Vocabulary::Restriction->value();
	my $owlOnProperty  = $ODO::Ontology::OWL::Vocabulary::onProperty->value();
	my $queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$rdfType>, <$owlRestriction>)";
	my $queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) > 1 ) {
		my $error =
"Must have exactly ONE (1) rdf:type property specified for restriction, you have "
		  . scalar( @{$queryResults} )
		  . ".\nTried following query:\n$queryString";

		#throw ODO::Exception::Ontology::OWL::Parse( error => $error );
		warn($error);
	}
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$owlOnProperty>, ?propertyURI)";
	$queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) > 1 ) {
		my $error =
		    "Can not have multiple owl:onProperty properties for restriction, you have "
		  . scalar( @{$queryResults} )
		  . ".\nTried following query:\n$queryString";

		#throw ODO::Exception::Ontology::OWL::Parse(error => $error );
		warn $error;
	} else {

		# Get the URI of the property that this restriction applies to
		$restriction->{'onProperty'} = $queryResults->[0]->object()->value()
		  if scalar @{$queryResults} == 1;
	}

	#
	# Get the restriction's cardinality
	#
	my $minCardinality = $ODO::Ontology::OWL::Vocabulary::minCardinality->value();
	my $maxCardinality = $ODO::Ontology::OWL::Vocabulary::maxCardinality->value();
	my $cardinality    = $ODO::Ontology::OWL::Vocabulary::cardinality->value();
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$cardinality>, ?cardinality)";
	$queryResults = $self->graph()->query($queryString)->results();

	# Convenience cardinality property
	if ( scalar( @{$queryResults} ) == 1 ) {

		# TODO: Can't have a minCardinality and maxCardinality if cardinality is present
		my $cardinality = $queryResults->[0]->object()->value();
		throw ODO::Exception::Ontology::OWL::Parse(
						   error => "owl:cardinality did not have 0 or 1 as its value" )
		  if ( $cardinality !~ /^(0|1)$/ );
		$restriction->{'minCardinality'} = $cardinality;
		$restriction->{'maxCardinality'} = $cardinality;
	} else {

		# Check for a specific set of cardinality restraints
		$queryString =
		  "SELECT ?stmt WHERE (<$restrictionURI>, <$minCardinality>, ?cardinality)";
		$queryResults = $self->graph()->query($queryString)->results();

		# minCardinality
		if ( scalar( @{$queryResults} ) == 1 ) {
			my $cardinality = $queryResults->[0]->object()->value();
			throw ODO::Exception::Ontology::OWL::Parse(
				  error => "owl:minCardinality is not a numerical value: $cardinality" )
			  if ( $cardinality !~ /^\d+$/ );
			$restriction->{'minCardinality'} = $cardinality;
		} else {

			# TODO: Error checking here
		}
		$queryString =
		  "SELECT ?stmt WHERE (<$restrictionURI>, <$maxCardinality>, ?cardinality)";
		$queryResults = $self->graph()->query($queryString)->results();

		# maxCardinality
		if ( scalar( @{$queryResults} ) == 1 ) {
			my $cardinality = $queryResults->[0]->object()->value();
			throw ODO::Exception::Ontology::OWL::Parse(
								error => "owl:maxCardinality is not a numerical value" )
			  if ( $cardinality !~ /^\d+$/ );
			$restriction->{'maxCardinality'} = $cardinality;
		} else {

			# TODO: Error checking here
		}
	}    # End cardinality section

	#
	# Value restrictions
	#
	my $owlAllValuesFrom  = $ODO::Ontology::OWL::Vocabulary::allValuesFrom->value();
	my $owlSomeValuesFrom = $ODO::Ontology::OWL::Vocabulary::someValuesFrom->value();
	my $owlHasValue       = $ODO::Ontology::OWL::Vocabulary::hasValue->value();
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$owlAllValuesFrom>, ?values)";
	$queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) == 1 ) {
		$restriction->{'allValuesFrom'} = $queryResults->[0]->object()->value();
	}
	
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$owlSomeValuesFrom>, ?values)";
	$queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) == 1 ) {

		# Can only have allValuesFrom or someValuesFrom
		throw ODO::Exception::Ontology::OWL::Parse( error =>
"Can not specify owl:someValuesFrom because owl:allValuesFrom already exists"
		) if ( exists( $restriction->{'allValuesFrom'} ) );
		$restriction->{'someValuesFrom'} = $queryResults->[0]->object()->value();
	}
	$queryString =
      "SELECT ?stmt WHERE (<$restrictionURI>, <$owlHasValue>, ?values)";
    $queryResults = $self->graph()->query($queryString)->results();
    if ( scalar( @{$queryResults} ) == 1 ) {
        # Can only have allValuesFrom or someValuesFrom
        throw ODO::Exception::Ontology::OWL::Parse( error =>
"Can not specify owl:hasValue because owl:allValuesFrom or owl:someValuesFrom already exists"
        ) if ( exists( $restriction->{'allValuesFrom'} ) or exists( $restriction->{'someValuesFrom'} ) );
        $restriction->{'hasValue'} = $queryResults->[0]->object()->value();
        
        # extract the type if possible
        my $s = $queryResults->[0]->object()->value();
        my $p = $ODO::Ontology::RDFS::Vocabulary::type->value();
        $queryString = "SELECT ?stmt WHERE (<$s>, <$p>, ?values)";
	    $queryResults = $self->graph()->query($queryString)->results();
	    foreach (@{$queryResults}) {
	    	# ignore nodes typed as named individuals
	    	next if $_->object()->value() eq 'http://www.w3.org/2002/07/owl#NamedIndividual';
	    	$restriction->{'range'} = $_->object()->value();
	    	last;
	    }
#	    if ( scalar( @{$queryResults} ) == 1 ) {
#	        $restriction->{'range'} = $queryResults->[0]->object()->value();
#	    }
        
    }
	
	return bless $restriction, 'ODO::Ontology::OWL::Lite::Restriction';
}

sub getEquivalentClasses {
	my ( $self, $restrictionURI, $classURI ) = @_;
	my $restriction = { restrictionURI => $restrictionURI };

	#
	# Generic restriction processing
	#
	my $rdfType        = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $owlRestriction = $ODO::Ontology::OWL::Vocabulary::Restriction->value();
	my $owlOnProperty  = $ODO::Ontology::OWL::Vocabulary::onProperty->value();
	my $queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$rdfType>, <$owlRestriction>)";
	my $queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) > 1 ) {
		my $error =
"Must have exactly ONE (1) rdf:type property specified for restriction, you have "
		  . scalar( @{$queryResults} )
		  . ".\nTried following query:\n$queryString";

		#throw ODO::Exception::Ontology::OWL::Parse( error => $error );
		warn($error);
	}
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$owlOnProperty>, ?propertyURI)";
	$queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) > 1 ) {
		my $error =
		    "Can not have multiple owl:onProperty properties for restriction, you have "
		  . scalar( @{$queryResults} )
		  . ".\nTried following query:\n$queryString";

		#throw ODO::Exception::Ontology::OWL::Parse(error => $error );
		warn $error;
	} else {

		# Get the URI of the property that this restriction applies to
		$restriction->{'onProperty'} = $queryResults->[0]->object()->value()
		  if scalar @{$queryResults} == 1;
	}

	#
	# Get the restriction's cardinality
	#
	my $minCardinality = $ODO::Ontology::OWL::Vocabulary::minCardinality->value();
	my $maxCardinality = $ODO::Ontology::OWL::Vocabulary::maxCardinality->value();
	my $cardinality    = $ODO::Ontology::OWL::Vocabulary::cardinality->value();
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$cardinality>, ?cardinality)";
	$queryResults = $self->graph()->query($queryString)->results();

	# Convenience cardinality property
	if ( scalar( @{$queryResults} ) == 1 ) {

		# TODO: Can't have a minCardinality and maxCardinality if cardinality is present
		my $cardinality = $queryResults->[0]->object()->value();
		throw ODO::Exception::Ontology::OWL::Parse(
						   error => "owl:cardinality did not have 0 or 1 as its value" )
		  if ( $cardinality !~ /^(0|1)$/ );
		$restriction->{'minCardinality'} = $cardinality;
		$restriction->{'maxCardinality'} = $cardinality;
	} else {

		# Check for a specific set of cardinality restraints
		$queryString =
		  "SELECT ?stmt WHERE (<$restrictionURI>, <$minCardinality>, ?cardinality)";
		$queryResults = $self->graph()->query($queryString)->results();

		# minCardinality
		if ( scalar( @{$queryResults} ) == 1 ) {
			my $cardinality = $queryResults->[0]->object()->value();
			throw ODO::Exception::Ontology::OWL::Parse(
				  error => "owl:minCardinality is not a numerical value: $cardinality" )
			  if ( $cardinality !~ /^\d+$/ );
			$restriction->{'minCardinality'} = $cardinality;
		} else {

			# TODO: Error checking here
		}
		$queryString =
		  "SELECT ?stmt WHERE (<$restrictionURI>, <$maxCardinality>, ?cardinality)";
		$queryResults = $self->graph()->query($queryString)->results();

		# maxCardinality
		if ( scalar( @{$queryResults} ) == 1 ) {
			my $cardinality = $queryResults->[0]->object()->value();
			throw ODO::Exception::Ontology::OWL::Parse(
								error => "owl:maxCardinality is not a numerical value" )
			  if ( $cardinality !~ /^\d+$/ );
			$restriction->{'maxCardinality'} = $cardinality;
		} else {

			# TODO: Error checking here
		}
	}    # End cardinality section

	#
	# Value restrictions
	#
	my $owlAllValuesFrom  = $ODO::Ontology::OWL::Vocabulary::allValuesFrom->value();
	my $owlSomeValuesFrom = $ODO::Ontology::OWL::Vocabulary::someValuesFrom->value();
	my $owlHasValue       = $ODO::Ontology::OWL::Vocabulary::hasValue->value();
	
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$owlAllValuesFrom>, ?values)";
	$queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) == 1 ) {
		$restriction->{'allValuesFrom'} = $queryResults->[0]->object()->value();
	}
	
	$queryString =
	  "SELECT ?stmt WHERE (<$restrictionURI>, <$owlSomeValuesFrom>, ?values)";
	$queryResults = $self->graph()->query($queryString)->results();
	if ( scalar( @{$queryResults} ) == 1 ) {

		# Can only have allValuesFrom or someValuesFrom or hasValue
		throw ODO::Exception::Ontology::OWL::Parse( error =>
"Can not specify owl:someValuesFrom because owl:allValuesFrom already exists"
		) if ( exists( $restriction->{'allValuesFrom'} ) );
		$restriction->{'someValuesFrom'} = $queryResults->[0]->object()->value();
	}
	
	$queryString =
      "SELECT ?stmt WHERE (<$restrictionURI>, <$owlHasValue>, ?values)";
    $queryResults = $self->graph()->query($queryString)->results();
    if ( scalar( @{$queryResults} ) == 1 ) {
        # Can only have allValuesFrom or someValuesFrom or hasValue
        throw ODO::Exception::Ontology::OWL::Parse( error =>
"Can not specify owl:hasValue because owl:allValuesFrom or owl:someValuesFrom already exists"
        ) if ( exists( $restriction->{'allValuesFrom'} ) or exists( $restriction->{'someValuesFrom'} ) );
        $restriction->{'hasValue'} = $queryResults->[0]->object()->value();
        # extract the type if possible
        my $s = $queryResults->[0]->object()->value();
        my $p = $ODO::Ontology::RDFS::Vocabulary::type->value();
        $queryString = "SELECT ?stmt WHERE (<$s>, <$p>, ?values)";
        $queryResults = $self->graph()->query($queryString)->results();
        foreach (@{$queryResults}) {
        	#ignore nodes typed as named individuals
            next if $_->object()->value() eq 'http://www.w3.org/2002/07/owl#NamedIndividual';
            $restriction->{'range'} = $_->object()->value();
            last;
        }
#        if ( scalar( @{$queryResults} ) == 1 ) {
#            $restriction->{'range'} = $queryResults->[0]->object()->value();
#        }
    }
	
	return bless $restriction, 'ODO::Ontology::OWL::Lite::Fragments::EquivalentClass';
}

#
#
#
sub getObjectProperties {
	my $self              = shift;
	my $rdfType           = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $owlObjectProperty = $ODO::Ontology::OWL::Vocabulary::ObjectProperty->value();
	my $owlInverseFunctionalProperty =
	  $ODO::Ontology::OWL::Vocabulary::InverseFunctionalProperty->value();
	my $owlTransitiveProperty =
	  $ODO::Ontology::OWL::Vocabulary::TransitiveProperty->value();
	my $owlSymmetricProperty =
	  $ODO::Ontology::OWL::Vocabulary::SymmetricProperty->value();

#
# Gather all of the various forms of ObjectProperty in to one array to be
# processed in to its component parts later (InverseFunctional, Transitive, Symmetric and
# Functional)
#
	my $queryString =
	  "SELECT ?stmt WHERE (?findPropertyID, <$rdfType>, <$owlObjectProperty>)";
	my $resultsGraph = ODO::Graph::Simple->Memory();
	$resultsGraph->add( scalar( $self->graph()->query($queryString)->results() ) );
	$queryString =
"SELECT ?stmt WHERE (?findPropertyID, <$rdfType>, <$owlInverseFunctionalProperty>)";
	$resultsGraph->add( scalar( $self->graph()->query($queryString)->results() ) );
	$queryString =
	  "SELECT ?stmt WHERE (?findPropertyID, <$rdfType>, <$owlTransitiveProperty>)";
	$resultsGraph->add( scalar( $self->graph()->query($queryString)->results() ) );
	$queryString =
	  "SELECT ?stmt WHERE (?findPropertyID, <$rdfType>, <$owlSymmetricProperty>)";
	$resultsGraph->add( scalar( $self->graph()->query($queryString)->results() ) );
	my $results = $resultsGraph->query($ODO::Query::Simple::ALL_STATEMENTS)->results();

	# UNDO Ignore anonymous property definitions
	my @tmp;
	foreach my $tmp_r ( @{$results} ) {
		push @tmp, $tmp_r;
		  #unless ( UNIVERSAL::isa( $tmp_r->subject(), 'ODO::Node::Blank' ) );
	}
	$results = \@tmp;
	return (wantarray) ? @{$results} : bless $results,
	  'ODO::Ontology::OWL::Lite::Fragments::ObjectProperties';
}

sub getDatatypeProperties {
	my $self    = shift;
	my $rdfType = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $owlDatatypeProperty =
	  $ODO::Ontology::OWL::Vocabulary::DatatypeProperty->value();
	my $queryString =
	  "SELECT ?stmt WHERE (?dvPropertyID, <$rdfType>, <$owlDatatypeProperty>)";
	my $results = $self->graph()->query($queryString)->results();

	# UNDO Ignore anonymous property definitions
	my @tmp;
	foreach my $tmp_r ( @{$results} ) {
		push @tmp, $tmp_r;
		  #unless ( UNIVERSAL::isa( $tmp_r->subject(), 'ODO::Node::Blank' ) );
	}
	$results = \@tmp;
	return (wantarray) ? @{$results} : bless $results,
	  'ODO::Ontology::OWL::Lite::Fragments::DatatypeProperties';
}

sub getAnnotationProperties {
	my $self    = shift;
	my $rdfType = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $owlAnnotationProperty =
	  $ODO::Ontology::OWL::Vocabulary::AnnotationProperty->value();
	my $queryString =
	  "SELECT ?stmt WHERE (?dvPropertyID, <$rdfType>, <$owlAnnotationProperty>)";
	my $results = $self->graph()->query($queryString)->results();
	return (wantarray) ? @{$results} : bless $results,
	  'ODO::Ontology::OWL::Lite::Fragments::AnnotationProperties';
}

sub getDatatypes {
	my $self        = shift;
	my $rdfType     = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $rdfDatatype = $ODO::Ontology::RDFS::Vocabulary::Datatype->value();
	my $queryString = "SELECT ?stmt WHERE (?dvPropertyID, <$rdfType>, <$rdfDatatype>)";
	my $results     = $self->graph()->query($queryString)->results();

	# UNDO Ignore anonymous property definitions
	my @tmp;
	foreach my $tmp_r ( @{$results} ) {
		push @tmp, $tmp_r;
		  # unless ( UNIVERSAL::isa( $tmp_r->subject(), 'ODO::Node::Blank' ) );
	}
	$results = \@tmp;
	return (wantarray) ? @{$results} : bless $results,
	  'ODO::Ontology::OWL::Lite::Fragments::Datatypes';
}

sub hasFunctionalProperty {
	my ( $self, $property ) = @_;
	my $propertyURI = $property;
	$propertyURI = $property->value()
	  if ( $property->isa( 'ODO::Node::Resource' ) );
	my $rdfType               = $ODO::Ontology::RDFS::Vocabulary::type->value();
	my $owlFunctionalProperty = $ODO::Ontology::RDFS::Vocabulary::Datatype->value();
	my $queryString =
	  "SELECT ?stmt WHERE (<$propertyURI>, <$rdfType>, <$owlFunctionalProperty>)";
	my $results = $self->graph()->query($queryString)->results();
	return ( scalar( @{$results} ) );
}

sub getPropertyRange {
	my ( $self, $propertyURI ) = @_;
	my $rdfRange    = $ODO::Ontology::RDFS::Vocabulary::range->value();
	my $queryString = "SELECT ?stmt WHERE (<$propertyURI>, <$rdfRange>, ?range)";
	my $results     = $self->graph()->query($queryString)->results();
	die("Error querying for range ($queryString)")
	  unless ( ref $results eq 'ARRAY' );
	return (wantarray) ? @{$results} : $results;
}

sub getPropertyDomain {
	my ( $self, $propertyURI ) = @_;
	my @domains;
	my $rdfDomain   = $ODO::Ontology::RDFS::Vocabulary::domain->value();
	my $owlClass    = $ODO::Ontology::OWL::Vocabulary::Class->value();
	my $owlUnionOf  = $ODO::Ontology::OWL::Vocabulary::unionOf->value();
	my $queryString = "SELECT ?stmt WHERE (<$propertyURI>, <$rdfDomain>, ?domains)";
	my $results     = $self->graph()->query($queryString)->results();

	# If this domain is a union .. break them out
	if ( scalar( @{$results} ) == 1 ) {
		my $unionURI = $results->[0]->object()->value();
		$queryString = "SELECT ?stmt WHERE (<$unionURI>, <$owlUnionOf>, ?list)";
		my $unionResults = $self->graph()->query($queryString)->results();
		return (wantarray) ? @{$results} : $results
		  unless ( scalar( @{$unionResults} ) > 0 );
		my $list = ODO::RDFS::List->new( $unionResults->[0]->object(), $self->graph() );
		my $listIter = ODO::Ontology::RDFS::List::Iterator->new($list);
		throw ODO::Exception::Runtime(
								   error => "Could not create iterator for ODO::RDFS::List" )
		  unless ( $listIter->isa( 'ODO::Ontology::RDFS::List::Iterator' ) );

		# Iterate through the list keeping the string value in the results
		# returned to the caller
		$results = [];
		my $iterElement;
		while ( ( $iterElement = $listIter->next() ) ) {
			if ( $iterElement->isa( 'ODO::Node::Blank' ) ) {

				# FIXME: ???
			} else {
				push @{$results}, $iterElement->value();
			}
		}
	}
	return (wantarray) ? @{$results} : $results;
}

sub init {
	my ( $self, $config ) = @_;
	$self->params( $config, qw/graph/ );
	if ( !$self->graph() ) {
		throw ODO::Exception::Parameter::Invalid( error => "slkfdjsl" );
	}
	return $self;
}
1;
__END__;
