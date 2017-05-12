#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/RDFS.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  03/02/2005
# Revision:	$Id: RDFS.pm,v 1.54 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::RDFS;

use strict;
use warnings;

use Data::Dumper;

use ODO::Statement;

use ODO::Ontology::RDFS::PerlEntity;
use ODO::Ontology::RDFS::Vocabulary;
use ODO::Ontology::RDFS::ObjectWriter;

use base qw/ODO::Ontology/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.54 $ =~ /: (\d+)\.(\d+)/;

our $BASECLASS_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/#base_class';
our $BOOTSTRAPPED_TYPE = "(?:${ODO::Ontology::RDFS::Vocabulary::RDF}|${ODO::Ontology::RDFS::Vocabulary::RDFS})";

our $CLASS_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/classes/';
our $PROPERTY_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/properties/';

our $CLASS_IMPL_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/classes/impls';
our $PROPERTY_IMPL_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/properties/impls';
our $PROPERTY_ACC_IMPL_SYMTAB_URI = 'http://ibm-slrp.sourceforge.net/uris/odo/2007/01/rdfs/properties/accessors/impls';

__PACKAGE__->mk_accessors(qw/property_namespace class_impls class_property_accessor_impls property_impls/);

=head1 NAME

ODO::Ontology::RDFS - RDFS to Perl code generator frontend.

=head1 SYNOPSIS

 use ODO::Node;
 use ODO::Graph::Simple;
 use ODO::Ontology::RDFS;
 
 my $schema = ODO::Graph::Simple->Memory(name=> 'Schema Model');
 my $source_data = ODO::Graph::Simple->Memory(name=> 'Source Data model');
 
 my ($statements, $imports) = ODO::Parser::XML->parse_file('/path/to/a/file.xml');
 $schema->add($statements);
 
 print STDERR "Generating Perl schema\n";
 my $SCHEMA = ODO::Ontology::RDFS->new(graph=> $source_data, schema_graph=> $schema);
 
 # $SCHEMA is_a ODO::Ontology::RDFS::PerlEntity
 my $resource = RDFS::Resource->new(ODO::Node::Resource->new('http://tempuri.org/someResource'), $source_data);

 my $klass = RDFS::Class->new(ODO::Node::Resource->new('http://tempuri.org/someClassDefinition'), $source_data);
 
=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=over

=item define_schema_objects( )

Get all class data:

1. Get all subjects with type Class
    - the name of the class is provided by the label
    - the comment is a description of the class
    - the definition is a URI where you can find the actual definition of the the object (definition and isDefinedBy should be methods)
    - record any explicit subclasses with the subClassOf triple
2. Get all properties with their domain being in the class from step 1
    - Access them with a general property( $name, [ $value ] ) method ?
3. Build objects

=cut

sub define_schema_objects {
	my $self = shift;
	
	my $class_list = $self->get_class_uris();
	my $property_list = $self->get_property_uris();

	$self->forward_declare_classes( $class_list );
	$self->foward_declare_properties( $property_list );

	$self->define_class_objects( $class_list );
	$self->define_property_objects( $property_list );
}


=item define_class_objects( )

=cut

sub define_class_objects {
	my ($self, $class_uri_list) = @_;
	
	# The components of a Perl class object from an RDFS #Class type are the following: 
	# 1. Perl Package
	# 2. Constructor
	# 3. Property container
	#
	foreach my $rdfs_class (@{ $class_uri_list }) {
		
		my $class_uri = $rdfs_class->value();
		
		next # skip already defined classes
			if($self->get_symtab_entry($CLASS_IMPL_SYMTAB_URI, $class_uri));
		
		my $constructorData = $self->get_constructor_data($class_uri);
		
		throw ODO::Exception::Runtime(error=> "Could not get constructor data for class URI: $class_uri")
			unless($constructorData);
		
		# Add the object's URI to the contstructor's data
		$constructorData->{'URI'} = $class_uri;
		
		
		my $perl_class_data = $self->get_class_data($class_uri);

		throw ODO::Exception::Runtime(error=> "Could not get class data for class URI: $class_uri")
			unless($perl_class_data);
		
		#
		# Now make the objects that will eventually serialze to 
		# the textual representation
		#
		
		my $constructor = ODO::Ontology::RDFS::ObjectWriter::Constructor->new(%{ $constructorData });
		throw ODO::Exception::Runtime(error=> "Could not create ODO::Ontology::RDFS::ObjectWriter::Constructor object for class URI: $class_uri")
			unless(UNIVERSAL::isa($constructor, 'ODO::Ontology::RDFS::ObjectWriter::Constructor'));
		
		$perl_class_data->{'constructor'} = $constructor;
				
		my $package = ODO::Ontology::RDFS::ObjectWriter::Package->new(%{ $perl_class_data } );
		throw ODO::Exception::Runtime(error=> "Could not create class definition for class URI: $class_uri")
			unless(UNIVERSAL::isa($package, 'ODO::Ontology::RDFS::ObjectWriter::Package'));
		
		$self->add_symtab_entry($CLASS_IMPL_SYMTAB_URI, $class_uri, $package);
		
		# Remove the base_class URI because it does not have an associated
		# PropertiesContainer
		delete($perl_class_data->{'inheritanceMap'}->{ $BASECLASS_URI })
			if(	   exists($perl_class_data->{'inheritanceMap'})
			   	&& exists($perl_class_data->{'inheritanceMap'}->{ $BASECLASS_URI })) ;
		
		my $superProperties = {};
		foreach my $sp (keys(%{ $perl_class_data->{'inheritanceMap'} })) {
			unless (defined $perl_class_data->{'inheritanceMap'}->{$sp}) {
				delete $perl_class_data->{'inheritanceMap'}->{$sp};
				next;
			}
			my $cn = $self->make_perl_package_name($self->get_symtab_entry($CLASS_SYMTAB_URI, $sp), 'PropertiesContainer');
			if ($cn eq 'PropertiesContainer') {
				$cn = "ODO::RDFS::Container";
			}
			$superProperties->{ $cn } = $cn;
		}
		
		my $propertyContainerData = {
			packageName=> $package->packageName(),
			inheritanceMap=> $superProperties,
			properties=> $package->properties(),
		};
		
		# We can't have a blank ISA
		if(scalar(values(%{ $superProperties })) > 0) {
			$propertyContainerData->{'ISA'} = [ values(%{ $superProperties }) ];
		}
		
		my $classPropertyContainer = ODO::Ontology::RDFS::ObjectWriter::PropertiesContainer->new(%{ $propertyContainerData });
		$self->add_symtab_entry($PROPERTY_ACC_IMPL_SYMTAB_URI, $class_uri, $classPropertyContainer);
	}
}


=item define_property_objects( )

=cut

sub define_property_objects {
	my ($self, $property_uri_list) = @_;
	
	foreach my $property (@{ $property_uri_list }) {
		
		my $property_uri = $property->value();
		
		next # skip previously defined properties
			if($self->get_symtab_entry($PROPERTY_IMPL_SYMTAB_URI, $property_uri));

		# 
		# CREATE A PROPERTY
		#
		# Gather and format all of the necessary data to create
		# the definition for the Property named by $property_uri
		#
		
		my $constructorData = $self->get_constructor_data($property_uri);
		throw ODO::Exception::Runtime(error=> "Could not get constructor data for property URI: $property_uri")
			unless(UNIVERSAL::isa($constructorData, 'HASH'));
		
		$constructorData->{'URI'} = $property_uri;
		
		
		my $propertyData = $self->get_property_data($property_uri);
		throw ODO::Exception::Runtime(error=> "Could not get property data for: $property_uri")
			unless(UNIVERSAL::isa($propertyData, 'HASH'));
		
		
		# High level objects now
		
	
		my $constructor = ODO::Ontology::RDFS::ObjectWriter::Constructor->new(%{ $constructorData });
		throw ODO::Exception::Runtime(error=> "Could not create ODO::Ontology::RDFS::ObjectWriter::Constructor object for property URI: $property_uri")
			unless(UNIVERSAL::isa($constructor, 'ODO::Ontology::RDFS::ObjectWriter::Constructor'));
		
		$propertyData->{'constructor'} = $constructor;
		
		
		my $package = ODO::Ontology::RDFS::ObjectWriter::Package->new( %{ $propertyData } );
		throw ODO::Exception::Runtime(error=> "Could not create Property definition for: $property_uri")
			unless($package);
		
		$self->add_symtab_entry($PROPERTY_IMPL_SYMTAB_URI, $property_uri, $package);
		
		
		#
		# CREATE A CONTAINER
		#
		# Now, gather and format all of the necessary data to create the 
		# PropertiesContainer that holds all of the propeties for a the
		# URI, $property_uri
		#
		
		#
		# We need to create an inheritance path that is similar to the
		# rdf:Property itself except that this path is for its PropertiesContainer
		# object.
		#
		
		my $superProperties = {};
		foreach my $sp (keys(%{ $propertyData->{'inheritanceMap'} })) {
			unless (defined $propertyData->{'inheritanceMap'}->{$sp}) {
				delete $propertyData->{'inheritanceMap'}->{$sp};
				next;
			}
			# FIXME: Properties that directly inherit from rdf:Property must use getClassName instead
			# because rdf:Property isa rdf:Class and was or will be defined as such
			my $propertyName = $self->get_symtab_entry($CLASS_SYMTAB_URI, $sp) ;
			if(0 && $sp eq $ODO::Ontology::RDFS::Vocabulary::Property->value()
			   || $sp eq $ODO::Ontology::RDFS::Vocabulary::Class->value()
			   || $sp eq $ODO::Ontology::RDFS::Vocabulary::Literal->value()
			   || $sp eq $ODO::Ontology::RDFS::Vocabulary::Resource->value()) {
				$propertyName = $self->get_symtab_entry($CLASS_SYMTAB_URI, $sp);
			}
			elsif(!$propertyName) {			
				$propertyName = $self->get_symtab_entry($PROPERTY_SYMTAB_URI, $sp);
			}
			
#			unless($propertyName) {			
#				die("Could not get property name for URI: $sp while creating property: $property_uri");
#			}
			
			my $cn = $self->make_perl_package_name($propertyName, 'PropertiesContainer');
			$superProperties->{ $cn } = $cn;
		}

		my $propertyContainerData = {
			packageName=> $package->packageName(),
			properties=> $package->properties(),
		};

		# We can't have a blank ISA
		if(scalar(values(%{ $superProperties })) > 0) {
			$propertyContainerData->{'ISA'} = [ values(%{ $superProperties }) ];
		}

		my $propertyContainer = ODO::Ontology::RDFS::ObjectWriter::PropertiesContainer->new(%{ $propertyContainerData });
		throw ODO::Exception::Runtime(error=> "Could not create PropertyContainer definition for: $property_uri")
			unless($propertyContainer);
		
		$self->add_symtab_entry($PROPERTY_ACC_IMPL_SYMTAB_URI, $property_uri, $propertyContainer);

	}
}


=item eval_schema_objects( )

=cut

sub eval_schema_objects {
	my $self = shift;
	
	my %evald;
	
	my @uri_list = keys( %{ $self->get_symbol_table($CLASS_SYMTAB_URI)->{'uris'} } );
	foreach my $uri (@uri_list) {
		next 
			unless($self->get_symtab_entry($CLASS_IMPL_SYMTAB_URI, $uri)
			    && !exists($evald{$uri})
			    && !defined($evald{$uri}));
		throw ODO::Exception::Runtime(error=> "Failed to evaluate object: $uri")
			unless($self->eval_object($uri, \%evald, $CLASS_IMPL_SYMTAB_URI));
	}
	
	@uri_list = keys( %{ $self->get_symbol_table($PROPERTY_SYMTAB_URI)->{'uris'} } );

	foreach my $uri (@uri_list) {
	
		next 
			unless($self->get_symtab_entry($PROPERTY_IMPL_SYMTAB_URI, $uri)
			    	&& !exists($evald{$uri})
			    	&& !defined($evald{$uri}));
		
		throw ODO::Exception::Runtime(error=> "Failed to evaluate object: $uri")
			unless($self->eval_object($uri, \%evald, $PROPERTY_IMPL_SYMTAB_URI));
	}
}


=item eval_object( )

=cut

sub eval_object {
	my ($self, $uri, $evald_hash, $impl_source) = @_;
	
	my $isa = $self->get_symtab_entry($impl_source, $uri)->inheritanceMap();
	
	if($isa) {
		my %parents = %{ $isa };
		
		foreach my $p_uri (keys(%parents)) {
			
			next # Ignore already eval'd objects
				if(	   !$self->get_symtab_entry($CLASS_IMPL_SYMTAB_URI, $p_uri)
					|| (exists($evald_hash->{$p_uri}) && defined($evald_hash->{$p_uri})) );
			
			throw ODO::Exception::Runtime(error=> "Failed to evaluate parent object: $p_uri for URI: $uri")
				unless($self->eval_object($p_uri, $evald_hash, $impl_source));
		}
	}
	eval ($self->get_symtab_entry($impl_source, $uri)->serialize());
	throw ODO::Exception::Runtime(error=> "Failed in evaluation for object defined by: $uri -> $@")
		if($@);
	
	eval ($self->get_symtab_entry($PROPERTY_ACC_IMPL_SYMTAB_URI, $uri)->serialize());
	throw ODO::Exception::Runtime(error=> "Failed in evaluation for PropertyContainer object defined by: $uri -> $@")
		if($@);
	
	$evald_hash->{$uri} = 1;
	
	return 1;
}


=item getObjectProperties( $objectURI ) 

Finding properties of a particular class means finding all triples that 
have the class's subject URI and the form <any, rdfs:domain> <subject URI>

=cut

sub getObjectProperties {
	my $self = shift;
	
	my $objectURI = shift;
	
	my $property_uris = $self->getPropertiesInDomain($objectURI);
	
	return undef
		unless(UNIVERSAL::isa($property_uris, 'ARRAY'));
	
	my @property_list;
	
	# TODO: Don't need to have two arrays here just one is enough
	foreach my $p (@{ $property_uris }) {
		
		my $property_uri = $p->value();
					
		my $name = $self->get_symtab_entry($PROPERTY_SYMTAB_URI, $property_uri );
		
		# Duplicate properties mean that the property is used in multiple Classes
		# which is why we don't check the return value of add_property_name.
		throw ODO::Ontology::DuplicatePropertyException("Could not find property name for URI: $property_uri")
			unless($name);
		
		my $property = {
			objectURI=> $property_uri,
			packageName=> $name,
			shortName=> $name,
		};
		
		if($name =~ /.*\:\:(.*)$/) {
			$property->{'shortName'} = $1;
		}
		
		push @property_list, $property;
	}
	
	return \@property_list;
}


=item get_constructor_data( $uri )

=cut

sub get_constructor_data {
	my ($self, $object_uri) = @_;
	
	my $class_name = ($self->get_symtab_entry($CLASS_SYMTAB_URI, $object_uri) || $self->get_symtab_entry($PROPERTY_SYMTAB_URI, $object_uri));
	my $property_container_package = $self->make_perl_package_name($class_name, 'PropertiesContainer');
	
	my $schema_uri = $self->getSchemaData($object_uri, $ODO::Ontology::RDFS::Vocabulary::isDefinedBy);
	$schema_uri = join('', @{ $schema_uri });
	
	my $description = $self->getSchemaData($object_uri, $ODO::Ontology::RDFS::Vocabulary::comment);
	$description = $self->__make_perl_string( join('', @{ $description } ) );

	my $object_properties = ($self->getObjectProperties($object_uri) || []);
	 	
	return {
		schemaURI=> 	$schema_uri,
		description=> 	$description,
		properties=> 	$object_properties,
		queryString=> 	"(?subj, rdf:type, <$object_uri>)",
		propertyContainerName=> $property_container_package,
	};
}


=item getSchemaData( $schemaObject, $property )

=cut

sub getSchemaData {
	my ($self, $schemaObject, $property) = @_;
	
	$schemaObject = ODO::Node::Resource->new( $schemaObject )
		unless(UNIVERSAL::isa($schemaObject, 'ODO::Node::Resource'));
		
	$property = ODO::Node::Resource->new( $property )
		unless(UNIVERSAL::isa($property, 'ODO::Node::Resource'));
	
	my $query = ODO::Query::Simple->new(s=> $schemaObject, p=> $property, o=> undef);
	my @results = map { $_->o()->value() } @{ $self->schema_graph()->query($query)->results() };
	return \@results;
}


=item get_class_data( $uri )

=cut

sub get_class_data {
	my ($self, $class_uri) = @_;
	my $perl_class_data = {
		objectURI=> $class_uri,
		packageName=> $self->get_symtab_entry($CLASS_SYMTAB_URI, $class_uri),
		useModules=> [ 'ODO', 'ODO::Query::Simple', 'ODO::Statement::Group', 'ODO::Ontology::RDFS::BaseClass' ],
		variables=> [],
	};
	
	# FIXME: Does this comment still make sense?
	# I believe that since there are instance requirements for the subClassOf and subPropertyOf 
	# properties, a rdf:Property can't contain both properties; the same being true for 
	# rdfs:Class definitions.
	my $subObjects = $self->getSchemaData($class_uri, $ODO::Ontology::RDFS::Vocabulary::subClassOf);

	if(scalar(@{ $subObjects }) > 0) {

		$perl_class_data->{'inheritanceMap'} = {};
		
		while(@{ $subObjects }) {
			my $sc = shift @{ $subObjects };
			$perl_class_data->{'inheritanceMap'}->{ $sc } = $self->get_symtab_entry($CLASS_SYMTAB_URI, $sc);
			unless (defined($perl_class_data->{'inheritanceMap'}->{ $sc })) {
				delete $perl_class_data->{'inheritanceMap'}->{ $sc };
				next;
			}
			# The base class should be included in the 'use ...' section
			# of the package definition
			push @{ $perl_class_data->{'useModules'} }, $self->get_symtab_entry($CLASS_SYMTAB_URI, $sc)
				if($sc eq $BASECLASS_URI);
		}
		
		if(scalar(values(%{ $perl_class_data->{'inheritanceMap'} })) > 0) {
			$perl_class_data->{'ISA'} = [ values(%{ $perl_class_data->{'inheritanceMap'} }) ];
			push @{ $perl_class_data->{'variables'} }, '@ISA';
		}
	}
	elsif($class_uri !~ /$BOOTSTRAPPED_TYPE/) {
		my $Class = $ODO::Ontology::RDFS::Vocabulary::Class->value();
		my $ClassPackageName = $self->get_symtab_entry($CLASS_SYMTAB_URI, $Class);
		if (defined $ClassPackageName) {
			$perl_class_data->{'inheritanceMap'} = { $Class=> $ClassPackageName };
			$perl_class_data->{'ISA'} = [ values(%{ $perl_class_data->{'inheritanceMap'} }) ];
			push @{ $perl_class_data->{'variables'} }, '@ISA';
		} else {
			$perl_class_data->{'inheritanceMap'} = { $Class=> "ODO::Ontology::RDFS::BaseClass"};
            $perl_class_data->{'ISA'} = [ values(%{ $perl_class_data->{'inheritanceMap'} }) ];
            push @{ $perl_class_data->{'variables'} }, '@ISA';
		}
	}
	return $perl_class_data;
}


=item get_property_data( $uri )

=cut

sub get_property_data {
	my ($self, $uri) = @_;
	
	my $propertyData = {
		objectURI=> $uri,
		packageName=> $self->get_symtab_entry($PROPERTY_SYMTAB_URI, $uri),
		useModules=> [ 'ODO', 'ODO::Query::Simple', 'ODO::Statement::Group', 'ODO::RDFS::Container' ],
		variables=> []
	};
	
	my $subObjects = $self->getSchemaData($uri, $ODO::Ontology::RDFS::Vocabulary::subPropertyOf);

	$propertyData->{'inheritanceMap'} = {};
	
	if(scalar(@{ $subObjects }) > 0) {
	
		while(@{ $subObjects }) {
			my $sp = shift @{ $subObjects };
			$propertyData->{'inheritanceMap'}->{ $sp } = $self->get_symtab_entry($PROPERTY_SYMTAB_URI, $sp);
			unless (defined($propertyData->{'inheritanceMap'}->{ $sp })) {
                delete $propertyData->{'inheritanceMap'}->{ $sp };
                next;
            }
		}

	}
	elsif($propertyData->{'objectURI'} ne $ODO::Ontology::RDFS::Vocabulary::Property) {

		my $Property = $ODO::Ontology::RDFS::Vocabulary::Property->value();
		my $PropertyPackageName = $self->get_symtab_entry($CLASS_SYMTAB_URI, $Property);
		if (defined $PropertyPackageName) {
			$propertyData->{'inheritanceMap'} = { $Property=> $PropertyPackageName };	
		}
	}
	else {
	}

	my $range = $self->getSchemaData($uri, $ODO::Ontology::RDFS::Vocabulary::range);
	
	if(scalar(@{ $range }) > 0) {
		
		$propertyData->{'range'} = {};
		
		while(@{ $range }) {

			my $sp = shift @{ $range };
			
			my $name = ($self->get_symtab_entry($CLASS_SYMTAB_URI, $sp) || $self->get_symtab_entry($PROPERTY_SYMTAB_URI, $sp)) ;
			
			#
			# The URI defined in the rdfs:range property may not be 
			# defined by the schema (hopefully it will though)
			#
			unless($name) {
				
				if($self->isClassURI($sp)) {
					$name = $self->uri_to_package_name($sp)
				}
				elsif($self->isPropertyURI($sp)) {
					$name = $self->uri_to_property_package_name($sp)
				}
				else {
					warn "rdfs:range points to a URI that is not defined as a rdfs:Class or rdf:Property - $sp\n";
					
					$name = $self->uri_to_package_name($sp);
				}
			}
			
			# Record the range information in its own hash to preserve the data
			# trail
			# 	AND
			# Record the range information in the inheritance structure so the
			# proper inheritance tree is constructed
			$propertyData->{'range'}->{ $sp } = $name;
			$propertyData->{'inheritanceMap'}->{ $sp } = $name;	
		}
	}
	push @{ $propertyData->{'variables'} }, '@ISA';
	# TODO this might not be necessary
	$propertyData->{'ISA'} = [ values(%{ $propertyData->{'inheritanceMap'} }) ] if scalar(values(%{ $propertyData->{'inheritanceMap'} }));
	$propertyData->{'ISA'} = ['ODO::RDFS::Container'] unless scalar(values(%{ $propertyData->{'inheritanceMap'} }));
	
	return $propertyData;	
}


=item get_rdfs_label( $uri )

=cut

sub get_rdfs_label {
	my ($self, $owner_uri) = @_;
	
	my $p = $ODO::Ontology::RDFS::Vocabulary::label;

	$owner_uri = ODO::Node::Resource->new( $owner_uri )
		    unless(UNIVERSAL::isa($owner_uri, 'ODO::Node::Resource'));
	
	my $query = ODO::Query::Simple->new(s=> undef, p=> $owner_uri, o=> $p);
	my $results = $self->schema_graph()->query($query)->results();
	
	return undef
		unless(ref $results eq 'ARRAY' && scalar(@{ $results }) > 0);
	
	return $self->__make_perl_string($results->[0]->value());
}


=item isPropertyURI( $uri )

=cut

sub isPropertyURI {
	my ($self, $uri) = @_;

	my $sourceGraph = $self->schema_graph();

	$uri = ODO::Node::Resource->new( $uri )
		    unless(UNIVERSAL::isa($uri, 'ODO::Node::Resource'));

	my $p = ODO::Node::Resource->new($ODO::Ontology::RDFS::Vocabulary::type);
	my $o = ODO::Node::Resource->new($ODO::Ontology::RDFS::Vocabulary::Property);
	
	my $match = ODO::Query::Simple->new($uri, $p, $o);
	
	my $results = $sourceGraph->query($match)->results();
	
	return 1
		if(UNIVERSAL::isa($results, 'ARRAY') && scalar(@{ $results }) > 0 );
	
	# Test if its a subPropertyOf
	$p = ODO::Node::Resource->new($ODO::Ontology::RDFS::Vocabulary::subPropertyOf);
	
	$results = $sourceGraph->query($match)->results();
	
	return 1
		if(UNIVERSAL::isa($results, 'ARRAY') && scalar(@{ $results }) > 0 );
	
	return 0;
}


=item isClassURI( $uri )

=cut

sub isClassURI {
	my ($self, $uri) = @_;

	my $sourceGraph = $self->schema_graph();

	$uri = ODO::Node::Resource->new( $uri )
		    unless(UNIVERSAL::isa($uri, 'ODO::Node::Resource'));

	my $p = $ODO::Ontology::RDFS::Vocabulary::type;
	my $o = $ODO::Ontology::RDFS::Vocabulary::Class;
	
	my $match = ODO::Query::Simple->new($uri, $p, $o);

	my $results = $sourceGraph->query($match)->results();
	
	return 1
		if(UNIVERSAL::isa($results, 'ARRAY') && scalar(@{ $results }) > 0 );

	# Test if its a subClassOf
	$p = $ODO::Ontology::RDFS::Vocabulary::subClassOf;
	
	$results = $sourceGraph->query($match)->results();
	
	return 1
		if(UNIVERSAL::isa($results, 'ARRAY') && scalar(@{ $results }) > 0 );
	
	return 0;
}


=item forward_declare_classes( $class_uri_list )

=cut

sub forward_declare_classes {
	my ($self, $class_uri_list) = @_;
	
	foreach my $class (@{ $class_uri_list }) {

		my $class_uri = $class->value();
		
		next
			if($self->get_symtab_entry($CLASS_SYMTAB_URI, $class_uri));
		
		my $package_name = $self->uri_to_package_name($class_uri);
		$self->add_symtab_entry($CLASS_SYMTAB_URI, $class_uri, $package_name);
	}
}


=item foward_declare_properties( $property_list )

=cut

sub foward_declare_properties {
	my ($self, $property_uri_list) = @_;

	foreach my $property (@{ $property_uri_list }) {

		my $property_uri = $property->value();
		
		next
			if($self->get_symtab_entry($PROPERTY_SYMTAB_URI, $property_uri));
		
		my $package_name = $self->uri_to_property_package_name($property_uri);
		$self->add_symtab_entry($PROPERTY_SYMTAB_URI, $property_uri, $package_name);
	}
}


=item get_class_uris( )

Finds all of the triples that fit the form: (subject, <rdf:type>, <rdfs:Class>)
Semantically: all of the RDFS classes in the graph.

=cut

sub get_class_uris {
	my $self = shift;

	my $p = $ODO::Ontology::RDFS::Vocabulary::type;
	my $o = $ODO::Ontology::RDFS::Vocabulary::Class;
	
	my $query = ODO::Query::Simple->new(s=> undef, p=> $p, o=> $o);
	my @subjects = map { $_->s(); } @{ $self->schema_graph()->query($query)->results() };
	return \@subjects;
}


=item get_property_uris( )

Finds all triples that fit the form: (<URI>, <rdf:type>, <rdf:Property>).
Semantically: Find all of the rdf:Properties in this graph.

=cut

sub get_property_uris {
	my $self = shift;

	my $p = $ODO::Ontology::RDFS::Vocabulary::type;
	my $o = $ODO::Ontology::RDFS::Vocabulary::Property;

	my $query = ODO::Query::Simple->new(s=> undef, p=> $p, o=> $o);
	
	my @subjects = map { $_->s() } @{ $self->schema_graph()->query($query)->results() };
	return \@subjects;
}


=item getPropertiesInDomain( $graph, $owner_uri )

Finds all of the triples that fit the form: (<ownerSubjectURI>, <rdf:type>, <rdfs:domain>)
Semantically: All subjects that have a domain restriction that is the owner class. These
should be <rdf:Properties>

=cut

sub getPropertiesInDomain {
	my ($self, $owner_uri) = @_;
	
	$owner_uri = ODO::Node::Resource->new( $owner_uri )
		    unless(UNIVERSAL::isa($owner_uri, 'ODO::Node::Resource'));
	
	my $domain = $ODO::Ontology::RDFS::Vocabulary::domain;
	
	my $query = ODO::Query::Simple->new(s=> undef, p=> $domain, o=> $owner_uri);
	
	my @subjects = map { $_->s() } @{ $self->schema_graph()->query($query)->results() };
	return \@subjects;
}


=item __uri_to_perl_identifier($uri)

=cut

sub __uri_to_perl_identifier {
	my ($self, $uri) = @_;
	
	# We need to find a good name for the URI given.. check the following 3 sources
	# in the following preferred order
	# 1. Find the URI's name and then try to add it in to the class name list,
	# 2.if it fails then we have a duplicate class name which is bad...
	# 3. The URI provides another method to get a name for a class		
	my $name = (  
			   ODO::Ontology::RDFS::Vocabulary->uri_to_name($uri)
		    || $self->get_rdfs_label($uri)
		    || $self->__parse_uri_for_name($uri)
		); 
	
	$name = $self->__make_perl_identifier( $name );
	
	$name = $self->make_perl_package_name($self->schema_name(), $name)
		if($self->schema_name());

	return $name;
}


=item uri_to_property_package_name( $uri )

=cut

sub uri_to_property_package_name {
	my ($self, $uri) = @_;
	my $name = $self->__uri_to_perl_identifier($uri);
	return $self->make_perl_package_name($self->property_namespace(), $name);
}


=item uri_to_package_name( $uri )

=cut

sub uri_to_package_name {
	my ($self, $uri) = @_;
	my $name = $self->__uri_to_perl_identifier($uri);	
	return $self->make_perl_package_name($self->base_namespace(), $name);
}


=item print_perl( )

=cut

sub print_perl {
	my ($self, $printRDFS, $fh) = @_;

	$fh = \*STDOUT
		unless($fh);
		
	my @impls = keys( %{ $self->get_symbol_table($CLASS_IMPL_SYMTAB_URI)->{'uris'} });
	
	foreach my $ci (@impls) {
		next
			if(	   !$printRDFS
				&& ODO::Ontology::RDFS::Vocabulary->uri_to_name($ci) );
		
		my $class = $self->get_symtab_entry($CLASS_IMPL_SYMTAB_URI, $ci );
		my $property_accessor = $self->get_symtab_entry($PROPERTY_ACC_IMPL_SYMTAB_URI, $ci );
		
		print $fh $class->serialize(), "\n";
		print $fh $property_accessor->serialize(), "\n";
	}

	@impls = keys( %{ $self->get_symbol_table($PROPERTY_IMPL_SYMTAB_URI)->{'uris'} });
	
	foreach my $pi (@impls) {
		next
			if(	   !$printRDFS
				&& ODO::Ontology::RDFS::Vocabulary->uri_to_name($pi) );
		
		my $property = $self->get_symtab_entry($PROPERTY_IMPL_SYMTAB_URI, $pi);
		my $property_accessor = $self->get_symtab_entry($PROPERTY_ACC_IMPL_SYMTAB_URI, $pi);
		
		print $fh $property->serialize(), "\n";
		print $fh $property_accessor->serialize(), "\n";
	}
	

}


=item bootstrap( )

=cut

sub bootstrap {
	my $self = shift;
	
	# Load the RDF associated with the RDFS schema and then add the base class URI
	# so that RDFS::Resource will have the correct inheritance structure
	my $graph = ODO::Graph::Simple->Memory();
	my $rdfs_schema_statements = ODO::Parser::XML->parse($ODO::Ontology::RDFS::Vocabulary::RDFS_SCHEMA_DATA);
	
	# TODO: Error check the parser
	
	$graph->add($rdfs_schema_statements);
	
	# <rdfs:Resource> <rdfs:subClassOf> <base_class URI>
	my $s = $ODO::Ontology::RDFS::Vocabulary::Resource;
	my $p = $ODO::Ontology::RDFS::Vocabulary::subClassOf;
	my $o_bc = ODO::Node::Resource->new($BASECLASS_URI);
	
	my $statement = ODO::Statement->new($s, $p, $o_bc);
	$graph->add($statement);
	
	my %config = (
		graph=> $graph,
		schema_graph=> $graph,
		base_class=> 'ODO::Ontology::RDFS::BaseClass',
		
		base_namespace=> 'RDFS',
		property_namespace=> 'RDFS::Properties',
	);
	
	foreach my $k (keys(%config)) {
		$self->{$k} = $config{$k};
	}
	
	$self->add_symtab_entry($CLASS_SYMTAB_URI, $BASECLASS_URI, 'ODO::Ontology::RDFS::BaseClass');
	
	$self->define_schema_objects();
	
	# Reset the boostrap specific state to undefined
	delete $self->{'base_namespace'};
}


sub init {
	my ($self, $config) = @_;
	if(!UNIVERSAL::can('ODO::RDFS::Resource', 'new')) {
		# Build the RDFS Perl code or just import 
		# already built code if available
		$self->bootstrap();
	}
	$self = $self->SUPER::init($config);
	$self->params($config, qw//);
	# Class package: <basePackage>::<schema_name>::*
	#
	# Property package: <basePackage>::<schema_name>::Properties::*
	my $pn = $self->make_perl_package_name($self->base_namespace(), 'Properties');
	$self->property_namespace($pn);
	$self->define_schema_objects();
	$self->eval_schema_objects();
	
	return ODO::Ontology::RDFS::PerlEntity->new(ontology=> $self);
}

=back

=head1 COPYRIGHT

Copyright (c) 2005-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html
  
=cut

1;

__END__
