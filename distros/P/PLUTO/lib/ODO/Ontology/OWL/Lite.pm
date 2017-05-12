#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Lite.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  02/28/2005
# Revision:	$Id: Lite.pm,v 1.93 2010-02-17 17:17:09 ubuntu Exp $
#
# Contributors:
#     IBM Corporation - initial API and implementation
#     Edward Kawas - bug fixes, etc
#
package ODO::Ontology::OWL::Lite;
use strict;
use warnings;

use ODO::Ontology::RDFS;
use ODO::Ontology::RDFS::Vocabulary;
use ODO::Ontology::OWL::Lite::Classes;
use ODO::Ontology::OWL::Lite::Properties;
use ODO::Ontology::OWL::Lite::ObjectWriter;
use base qw/ODO::Ontology/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.93 $ =~ /: (\d+)\.(\d+)/;

our $ANNOTATION_SYMTAB_URI =
  'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/annotation/';
our $CLASS_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/classes/';
our $DATATYPE_SYMTAB_URI =
  'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/datatypes/';
our $OBJECT_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/objects/';
our %object_property_map;
__PACKAGE__->mk_accessors(
						 qw/propertyObjects classObjects owlLiteNames implementations/);

sub objectPropertyMap {
	my $self = shift;
	return $self->propertyObjects->object;
}

sub datatypePropertyMap {
	my $self = shift;
	return $self->propertyObjects->datatype;
}

sub annotationPropertyMap {
	my $self = shift;
	return $self->propertyObjects->annotation;
}

# TODO this might not be right ...
sub classMap {
	my $self = shift;
	return $self->classObjects()->classes();
}

sub debug {
	my $self = shift;
	use Data::Dumper;
	open FILE, ">", "/tmp/data.txt" or return;
	print FILE "Annotations\n",
	  Dumper($self->annotationPropertyMap),
	  "datatypeProperties\n",
	  Dumper($self->datatypePropertyMap),
	  "objectProperties\n",
	  Dumper($self->objectPropertyMap),
	  "classes\n",
	  Dumper($self->classMap);
	close FILE;
}

sub normalize {
	my $self = shift;
	return unless $self->propertyObjects;
	return unless $self->propertyObjects->object;
	
	my $datatypeProperties = $self->propertyObjects->object;
	# pseudo code:
	# foreach objectProperty Y
	#   if Y has inverse
	#      X = inverseY
	#      setRangeX(domainY)
	#      setDomainX(rangeY)
	#      setInverseX(Y) <-:might not be important
	#
	
	my %processed;
	foreach my $property (keys %{$datatypeProperties}) {
		next if $processed{$property};
		if ($datatypeProperties->{$property}->{'inverses'}) {
			foreach my $inverse (@{$datatypeProperties->{$property}->{'inverses'}}) {
				next unless $datatypeProperties->{$inverse};		
				# set the domain
				push @{$self->propertyObjects->object->{$inverse}->{'domain'}}, @{$datatypeProperties->{$property}->{'range'}}
				    if defined $datatypeProperties->{$property}->{'range'} and @{$datatypeProperties->{$property}->{'range'}} > 0; 
				# set the range
				push @{$self->propertyObjects->object->{$inverse}->{'range'}}, @{$datatypeProperties->{$property}->{'domain'}}
                    if defined $datatypeProperties->{$property}->{'domain'} and @{$datatypeProperties->{$property}->{'domain'}} > 0;
                # TODO consider removing duplicates ...
			}
		}
		# mark as done
		$processed{$property} = 1;
	}
}

sub init {
	my ( $self, $config ) = @_;
	# check to see if we need to be verbose
	my $isVerbose = $config->{'verbose'} || undef;
	delete $config->{'verbose'};
	
	my $isImpl = $config->{'do_impl'} || undef;
	delete $config->{'do_impl'};

	$self = $self->SUPER::init($config);

	# Make sure we have RDFS eval'd in to our namespace
	# The ODO::Ontology::RDFS::Core object is remembered just in case
	my $RDFS = ODO::Ontology::RDFS->new( graph        => $self->graph(),
										 schema_graph => $self->schema_graph() );

	# Make sure we have the inheritance structure setup for classes
	$self->add_symtab_entry( $CLASS_SYMTAB_URI,
							 $ODO::Ontology::OWL::Vocabulary::Thing->value(),
							 'OWL::Thing' );

	# This preserves the inheritance structure for properties
	$self->add_symtab_entry( $OBJECT_SYMTAB_URI,
							 $ODO::Ontology::RDFS::Vocabulary::Property->value(),
							 'RDFS::Property' );
	$self->add_symtab_entry( $OBJECT_SYMTAB_URI,
							 $ODO::Ontology::OWL::Vocabulary::ObjectProperty->value(),
							 'OWL::ObjectProperty' );
	$self->add_symtab_entry( $ANNOTATION_SYMTAB_URI,
						   $ODO::Ontology::OWL::Vocabulary::AnnotationProperty->value(),
						   'OWL::AnnotationProperty' );
	$self->add_symtab_entry( $DATATYPE_SYMTAB_URI,
							 $ODO::Ontology::OWL::Vocabulary::DatatypeProperty->value(),
							 'OWL::DatatypeProperty' );

	# Fill the properties and classes of an OWL ontology
	my $p = ODO::Ontology::OWL::Lite::Properties->new( graph => $self->schema_graph() );
	$self->propertyObjects($p);
	my $c = ODO::Ontology::OWL::Lite::Classes->new( graph => $self->schema_graph() );
	$self->classObjects($c);
	$self->registerProperties();
	$self->registerClasses();
	my $classDescriptions = $self->defineClasses();
	
	if ($isImpl) {
		$self->implementations( ODO::Ontology::OWL::Lite::Implementations->new() );
		$self->implementations()->objectProperties( $self->defineObjectProperties() );
		$self->implementations()->datatypeProperties( $self->defineDatatypeProperties() );
		$self->implementations()->annotationProperties( $self->defineAnnotationProperties() );
		$self->implementations()->class( $classDescriptions->{'classes'} );
		$self->implementations()->propertyContainers( $classDescriptions->{'propertyContainers'} );
	}
    $self->normalize();
	# diagnostic ...
	eval {$self->debug;} if $isVerbose;
	return $self;
}

#
# registerClasses( )
#
sub registerClasses {
	my $self = shift;
	foreach my $classURI ( keys( %{ $self->classObjects()->classes() } ) ) {
		next if $classURI eq 'http://www.w3.org/2002/07/owl#Thing';
		my $className = $self->makeName($classURI);
		if ( $self->get_symtab_entry( $CLASS_SYMTAB_URI, $classURI ) ) {
			throw ODO::Exception::Ontology::DuplicateClass(
							   error => "Duplicate class defined with URI: $classURI" );
		} elsif ( $self->get_symtab_entry( $CLASS_SYMTAB_URI, $className ) ) {
			throw ODO::Exception::Ontology::DuplicateClass( error =>
"Duplicate class name '$className' found when adding class URI: $classURI"
			);
		} else {

			# FIXME: ??
		}
		$self->add_symtab_entry( $CLASS_SYMTAB_URI, $classURI, $className );
	}
}

#
# registerProperties( )
#
sub registerProperties {
	my $self = shift;
	foreach my $propertyURI ( keys( %{ $self->propertyObjects()->object() } ) ) {
		if (    $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $propertyURI )
			 || $self->get_symtab_entry( $ANNOTATION_SYMTAB_URI, $propertyURI )
			 || $self->get_symtab_entry( $DATATYPE_SYMTAB_URI,   $propertyURI ) )
		{
			throw ODO::Exception::Ontology::DuplicateProperty(
				   error => "Duplicate property for ObjectProperty URI: $propertyURI" );
		}
		my $propertyName = $self->makeName($propertyURI);
		if (    $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $propertyName )
			 || $self->get_symtab_entry( $ANNOTATION_SYMTAB_URI, $propertyName )
			 || $self->get_symtab_entry( $DATATYPE_SYMTAB_URI,   $propertyName ) )
		{
			throw ODO::Exception::Ontology::DuplicateProperty( error =>
"Duplicate property package name '$propertyName' for ObjectProperty URI: $propertyURI"
			);
		}
		$self->add_symtab_entry( $OBJECT_SYMTAB_URI, $propertyURI, $propertyName );
	}
	foreach my $propertyURI ( keys( %{ $self->propertyObjects()->annotation() } ) ) {
		if (    $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $propertyURI )
			 || $self->get_symtab_entry( $ANNOTATION_SYMTAB_URI, $propertyURI )
			 || $self->get_symtab_entry( $DATATYPE_SYMTAB_URI,   $propertyURI ) )
		{
			throw ODO::Exception::Ontology::DuplicateProperty( error =>
						"Duplicate property for AnnotationProperty URI: $propertyURI" );
		}
		my $propertyName = $self->makeName($propertyURI);
		if (    $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $propertyName )
			 || $self->get_symtab_entry( $ANNOTATION_SYMTAB_URI, $propertyName )
			 || $self->get_symtab_entry( $DATATYPE_SYMTAB_URI,   $propertyName ) )
		{
			throw ODO::Exception::Ontology::DuplicateProperty( error =>
"Duplicate property package name '$propertyName' for AnnotationProperty URI: $propertyURI"
			);
		}
		$self->add_symtab_entry( $ANNOTATION_SYMTAB_URI, $propertyURI, $propertyName );
	}
	foreach my $propertyURI ( keys( %{ $self->propertyObjects()->datatype() } ) ) {
		if (    $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $propertyURI )
			 || $self->get_symtab_entry( $ANNOTATION_SYMTAB_URI, $propertyURI )
			 || $self->get_symtab_entry( $DATATYPE_SYMTAB_URI,   $propertyURI ) )
		{
			throw ODO::Exception::Ontology::DuplicateProperty(
				 error => "Duplicate property for DatatypeProperty URI: $propertyURI" );
		}
		my $propertyName = $self->makeName($propertyURI);
		if (    $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $propertyName )
			 || $self->get_symtab_entry( $ANNOTATION_SYMTAB_URI, $propertyName )
			 || $self->get_symtab_entry( $DATATYPE_SYMTAB_URI,   $propertyName ) )
		{
			throw ODO::Exception::Ontology::DuplicateProperty( error =>
"Duplicate property package name '$propertyName' for DatatypeProperty URI: $propertyURI"
			);
		}
		$self->add_symtab_entry( $DATATYPE_SYMTAB_URI, $propertyURI, $propertyName );
	}
}

sub defineClasses {
	my $self = shift;
	my %classes;
	my %propertyContainers;
	foreach my $classURI ( keys( %{ $self->classObjects()->classes() } ) ) {

		#my $className = $self->classMap()->{ $classURI };
		my $className        = $self->makeName($classURI);
		my $objectProperties = [];
		foreach my $op ( @{ $self->getObjectPropertiesForClass($classURI) } ) {
			my $name = $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $op );
			push @{$objectProperties},
			  { shortName => $self->makeShortName($name), packageName => $name };
		}
		my $datatypeProperties = [];
		foreach my $dp ( @{ $self->getDatatypePropertiesForClass($classURI) } ) {
			my $name = $self->get_symtab_entry( $DATATYPE_SYMTAB_URI, $dp );
			push @{$datatypeProperties},
			  { shortName => $self->makeShortName($name), packageName => $name };
		}
		my $annotationProperties = [];
		foreach my $ap ( @{ $self->getAnnotationPropertiesForClass($classURI) } ) {
			my $name = $self->get_symtab_entry( $ANNOTATION_SYMTAB_URI, $ap );
			push @{$annotationProperties},
			  { shortName => $self->makeShortName($name), packageName => $name };
		}

		# Get the names of all the classes in the intersectionOf declaration
		my @classIntersections =
		  map { $self->classMap()->{$_} }
		  @{ $self->classObjects()->classes()->{$classURI}->{'intersections'}
			  ->{'classes'} };
		my $propertyContainerName =
		  $self->make_perl_package_name( $className, 'PropertiesContainer' );

   # Merge the intersected property restrictions with the standard property restrictions
		my @restrictions = (
				   @{ $self->classObjects()->classes()->{$classURI}->{'restrictions'} },
				   @{
					   $self->classObjects()->classes()->{$classURI}->{'intersections'}
						 ->{'restrictions'}
					 }
		);

  # Restriction properties are those properties defined in anonymous subclasses for this
  # class.
		my @restrictionProperties;
		foreach my $r (@restrictions) {
			next unless $r->{'onProperty'};
			my $propertyName =
			  (    $self->get_symtab_entry( $OBJECT_SYMTAB_URI, $r->{'onProperty'} )
				|| $self->get_symtab_entry( $DATATYPE_SYMTAB_URI, $r->{'onProperty'} )
				|| new ODO::Ontology::OWL::Vocabulary->uri_to_name($r->{'onProperty'})
				|| new ODO::Ontology::RDFS::Vocabulary->uri_to_name($r->{'onProperty'})
			  );
			#throw ODO::Exception::Ontology::MissingProperty(
			#	error =>
			warn "Unable to find property name for URI: " . $r->{'onProperty'} 
			. ".\nPlease make sure that your OWL file contains a declaration!" 
			  unless ($propertyName);
			  
			$propertyName = $self->makeName($r->{'onProperty'}) unless $propertyName;
			$r->{'propertyName'} = $propertyName;
			push @restrictionProperties,
			  {
				shortName   => $self->makeShortName($propertyName),
				packageName => $propertyName
			  };
		}
		my %constructorData = (
					  URI        => $classURI,
					  properties => [
									  @{$objectProperties},     @{$datatypeProperties},
									  @{$annotationProperties}, @restrictionProperties
					  ],
					  cardinalityRestrictions => \@restrictions,
					  classIntersections      => \@classIntersections,
					  restrictedIntersections =>
						$self->classObjects()->classes()->{$classURI}->{'intersections'}
						->{'restrictions'},
					  propertyContainerName => $propertyContainerName,
		);
		my $constructor =
		  ODO::Ontology::OWL::Lite::ObjectWriter::Constructor->new(%constructorData);
		my $inheritanceMap =
		  $self->makeInheritanceMap(
					 $self->propertyObjects()->object()->{$classURI}->{'inheritance'} );

		# If this is a top level object in the hierarchy for this schema then have it
		# inherit from OWL::Thing
		$inheritanceMap =
		  { $ODO::Ontology::OWL::Vocabulary::Thing->value() =>
			$self->classMap()->{ $ODO::Ontology::OWL::Vocabulary::Thing->value() }, }
		  unless ($inheritanceMap);
		my %classData = (
					 packageName => $className,
					 useModules  => [
									 'ODO',                      'ODO::Query::Simple',
									 'ODO::Query::RDQL::Parser', 'ODO::Statement::Group'
					 ],
					 constructor    => $constructor,
					 variables      => ['@ISA'],
					 ISA            => [ values( %{$inheritanceMap} ) ],
					 inheritanceMap => $inheritanceMap,
		);
		$classes{$classURI} =
		  ODO::Ontology::OWL::Lite::ObjectWriter::Package->new(%classData);

  # If there is intersection data, then we add named classes to the properties container
  # inheritance path
		foreach my $intersectClass (@classIntersections) {
			$inheritanceMap->{ $self->classMap()->{$intersectClass} } = $intersectClass
			  if defined $self->classMap()->{$intersectClass};
		}
		my $superPropertyInheritanceMap =
		  $self->makePropertiesContainerInheritanceMap($inheritanceMap);

		# Properties container
		my %propertyContainerData = (
								   packageName => $className,
								   ISA => [ values( %{$superPropertyInheritanceMap} ) ],
								   properties => $classes{$classURI}->properties(),
		);
		my $propertyContainer =
		  ODO::Ontology::OWL::Lite::ObjectWriter::PropertyContainer->new(
																%propertyContainerData);
		$propertyContainers{$classURI} = $propertyContainer;
	}
	return { classes => \%classes, propertyContainers => \%propertyContainers };
}

sub defineObjectProperties {
	my $self = shift;
	my @properties;
	my $objectPropertyURI  = $ODO::Ontology::OWL::Vocabulary::ObjectProperty->value();
	my $objectPropertyName = $self->objectPropertyMap()
	  ->{ $ODO::Ontology::OWL::Vocabulary::ObjectProperty->value() };
	foreach my $propertyURI ( keys( %{ $self->propertyObjects()->object() } ) ) {
		next
		  if ( $propertyURI =~
/^(${ODO::Ontology::OWL::Vocabulary::OWL}|${ODO::Ontology::RDFS::Vocabulary::RDF}|${ODO::Ontology::RDFS::Vocabulary::RDFS})/
		  );
		next    # Skip more specific property types
		  if (    exists( $self->propertyObjects()->annotation()->{$propertyURI} )
			   || exists( $self->propertyObjects()->datatype()->{$propertyURI} ) );
		my $propertyName = $self->objectPropertyMap()->{$propertyURI};
		my $propertyData = $self->defineProperty( $propertyURI, $propertyName );
		$propertyData->{'inheritanceMap'}->{$objectPropertyURI} = $objectPropertyName;
		push @{ $propertyData->{'ISA'} }, $objectPropertyName;
		my $package =
		  ODO::Ontology::OWL::Lite::ObjectWriter::Package->new( %{$propertyData} );
		push @properties, $package;
	}
	return \@properties;
}

sub defineDatatypeProperties {
	my $self = shift;
	my @properties;
	my $dataPropertyURI  = $ODO::Ontology::OWL::Vocabulary::DatatypeProperty->value();
	my $dataPropertyName = $self->datatypePropertyMap()->{$dataPropertyURI};
	foreach my $propertyURI ( keys( %{ $self->propertyObjects()->datatype() } ) ) {
		next
		  if ( $propertyURI =~
/^(${ODO::Ontology::OWL::Vocabulary::OWL}|${ODO::Ontology::RDFS::Vocabulary::RDF}|${ODO::Ontology::RDFS::Vocabulary::RDFS})/
		  );
		my $propertyName = $self->datatypePropertyMap()->{$propertyURI};
		my $propertyData = $self->defineProperty( $propertyURI, $propertyName );
		$propertyData->{'inheritanceMap'}->{$dataPropertyURI} = $dataPropertyName;
		push @{ $propertyData->{'ISA'} }, $dataPropertyName;
		my $package =
		  ODO::Ontology::OWL::Lite::ObjectWriter::Package->new( %{$propertyData} );
		push @properties, $package;
	}
	return \@properties;
}

sub defineAnnotationProperties {
	my $self = shift;
	my @properties;
	my $annotationPropertyURI =
	  $ODO::Ontology::OWL::Vocabulary::AnnotationProperty->value();
	my $annotationPropertyName =
	  $self->annotationPropertyMap()->{$annotationPropertyURI};
	foreach my $propertyURI ( keys( %{ $self->propertyObjects()->annotation() } ) ) {
		next
		  if ( $propertyURI =~
/^(${ODO::Ontology::OWL::Vocabulary::OWL}|${ODO::Ontology::RDFS::Vocabulary::RDF}|${ODO::Ontology::RDFS::Vocabulary::RDFS})/
		  );
		my $propertyName = $self->annotationPropertyMap()->{$propertyURI};
		my $propertyData = $self->defineProperty( $propertyURI, $propertyName );
		$propertyData->{'inheritanceMap'}->{$annotationPropertyURI} =
		  $annotationPropertyName;
		push @{ $propertyData->{'ISA'} }, $annotationPropertyName;
		my $package =
		  ODO::Ontology::OWL::Lite::ObjectWriter::Package->new( %{$propertyData} );
		push @properties, $package;
	}
	return \@properties;
}

sub defineProperty {
	my ( $self, $propertyURI, $propertyName ) = @_;
	my %constructorData = (
				URI        => $propertyURI,
				properties => [],
				propertyContainerName =>
				  $self->make_perl_package_name( $propertyName, 'PropertiesContainer' ),
	);
	my $constructor =
	  ODO::Ontology::OWL::Lite::ObjectWriter::Constructor->new(%constructorData);
	my $inheritanceMap =
	  $self->makeInheritanceMap(
				  $self->propertyObjects()->object()->{$propertyURI}->{'inheritance'} );

	# If this is a top level object in the hierarchy for this schema then have it
	# inherit from OWL::DatatypeProperty
	$inheritanceMap =
	  { $ODO::Ontology::RDFS::Vocabulary::Property->value() =>
		$self->objectPropertyMap()
		->{ $ODO::Ontology::RDFS::Vocabulary::Property->value() }, }
	  unless ($inheritanceMap);
	my %propertyData = (
				 packageName => $propertyName,
				 useModules => [ 'ODO', 'ODO::Query::Simple', 'ODO::Statement::Group' ],
				 constructor    => $constructor,
				 variables      => ['@ISA'],
				 ISA            => [ values( %{$inheritanceMap} ) ],
				 inheritanceMap => $inheritanceMap,
	);
	return \%propertyData;
}

#
# makeName( $uri )
#
sub makeName {
	my ( $self, $uri ) = @_;
	my $name;

	# We need to find a good name for the URI given.. check the following 3 sources
	# in the followeing preferred order
	# Find the URI's name and then try to add it in to the class name list,
	# if it fails then we have a duplicate class name which is bad...
	# The URI provides another method to get a name for a class
	$name =
	  (    ODO::Ontology::OWL::Vocabulary->uri_to_name($uri)
		|| ODO::Ontology::RDFS::Vocabulary->uri_to_name($uri)
		|| $self->__parse_uri_for_name($uri) );
	$name = $self->__make_perl_identifier($name);
	$name = $self->make_perl_package_name( $self->schema_name(), $name )
	  if ( $self->schema_name() );
	return $name;
}

sub makeShortName {
	my ( $self, $name ) = @_;
	unless ($name) {
		die('Could not make short name because long name is undefined');
	}
	my ($shortName) = $name =~ /::([^:]+)$/;
	return ( $shortName || $name );
}

sub makeInheritanceMap {
	my ( $self, $inheritedURIs ) = @_;

	#
	# Build the inheritance map
	#
	my $inheritanceMap   = {};
	my $isToplevelObject = 1;
	foreach my $superURI ( @{$inheritedURIs} ) {
		my $superName = $self->makeName($superURI);
		$inheritanceMap->{$superURI} = $superName;
		$isToplevelObject = 0;
	}
	return ($isToplevelObject) ? undef : $inheritanceMap;
}

sub makePropertiesContainerInheritanceMap {
	my $self           = shift;
	my $inheritanceMap = shift;
	my $im;
	foreach my $sp ( keys( %{$inheritanceMap} ) ) {
		$im->{$sp} = $self->make_perl_package_name( $inheritanceMap->{$sp},
													'PropertiesContainer' );
	}
	return $im;
}

sub getObjectPropertiesForClass {
	my $self     = shift;
	my $classURI = shift;
	my @properties;
	foreach my $propertyURI ( keys( %{ $self->objectPropertyMap() } ) ) {
		foreach my $uri (
				   @{ $self->propertyObjects()->object()->{$propertyURI}->{'domain'} } )
		{
			$uri = $uri->object->value if $uri->isa('ODO::Statement');
			push @properties, $propertyURI, next
			  if ( $uri eq $classURI );
		}
	}
	return \@properties;
}

sub getAnnotationPropertiesForClass {
	my $self     = shift;
	my $classURI = shift;
	my @properties;
#	foreach my $uri ( keys( %{ $self->annotationPropertyMap() } ) ) {
#	}
	return \@properties;
}

sub getDatatypePropertiesForClass {
	my $self     = shift;
	my $classURI = shift;
	my @properties;
	foreach my $propertyURI ( keys( %{ $self->datatypePropertyMap() } ) ) {
		foreach my $uri (
				 @{ $self->propertyObjects()->datatype()->{$propertyURI}->{'domain'} } )
		{
			push @properties, $propertyURI
			  if ( $uri eq $classURI );
		}
	}
	return \@properties;
}

package ODO::Ontology::OWL::Lite::Implementations;
use strict;
use warnings;
use base qw/ODO/;
__PACKAGE__->mk_accessors(
	qw/class propertyContainers objectProperties annotationProperties datatypeProperties/
);

sub print {
	my ( $self, $fh ) = @_;
	$fh = \*STDERR
	  unless ($fh);
	foreach my $tt ( @{ $self->annotationProperties() } ) {
		print $fh $tt->serialize();
	}
	foreach my $tt ( @{ $self->datatypeProperties() } ) {
		print $fh $tt->serialize();
	}
	foreach my $tt ( @{ $self->objectProperties() } ) {
		print $fh $tt->serialize();
	}
	foreach my $classURI ( keys( %{ $self->class() } ) ) {
		print $fh $self->class()->{$classURI}->serialize();
		print $fh $self->propertyContainers()->{$classURI}->serialize();
	}
}

sub evaluate {
	my $self = shift;
}

sub evaluateObject {
	my $self = shift;
}
1;
__END__
