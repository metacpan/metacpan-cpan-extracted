#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/81_ontology_rdfs.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/29/2006
# Revision:	$Id: 81_ontology_rdfs.t,v 1.6 2009-11-24 19:05:34 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use Test::More qw/no_plan/;

use strict;
use warnings;
use Data::Dumper;

sub BEGIN {
	use_ok('ODO::Graph::Simple');
	use_ok('ODO::Parser::XML');	
	use_ok('ODO::RDFS::Resource');
	use_ok('ODO::RDFS::Class');
	use_ok('ODO::Ontology::RDFS');
}

my $source_data = ODO::Graph::Simple->Memory({name=> 'Source Data model'});

my $schema_graph = ODO::Graph::Simple->Memory({name=> 'Schema Model'});
my ($statements, $imports) = ODO::Parser::XML->parse_file('t/data/rdfs_example_schema.xml');
$schema_graph->add($statements);


my $VEHICLES = ODO::Ontology::RDFS->new(graph=> $source_data, schema_graph=> $schema_graph);

isa_ok($VEHICLES, 'ODO::Ontology::RDFS::PerlEntity', 'Parsed RDF schema generated object');
isa_ok($VEHICLES->ontology(), 'ODO::Ontology::RDFS', 'Parsed RDF schema management object');

#
# Test whether or not we have the new objects
#
my $resource = ODO::RDFS::Resource->new(ODO::Node::Resource->new('http://tempuri.org/someResource'), $source_data);
isa_ok($resource, 'ODO::RDFS::Resource', 'Base class named Resource');

my $klass = ODO::RDFS::Class->new(ODO::Node::Resource->new('http://tempuri.org/someClassDefinition'), $source_data);
isa_ok($klass, 'ODO::RDFS::Class', 'Base class named Class');

my $van = Van->new(ODO::Node::Resource->new('http://tempuri.org/myVan'), $source_data);
isa_ok($van, 'MotorVehicle', 'Test object inheritance');

isa_ok($van->properties(), 'MotorVehicle::PropertiesContainer', 'Test the Property container object');
isa_ok($van->properties(), 'Van::PropertiesContainer', 'Test the Property container object');

my $driver = Properties::driver->new(ODO::Node::Resource->new('http://tempuri.org/firstname/lastname'), $source_data);
isa_ok($driver, 'Properties::driver', 'Test the driver Property object');

$van->properties()->driver($driver);
isa_ok($van->properties()->driver(), 'ARRAY', 'Test the Property container accessor');
isa_ok($van->properties()->driver()->[0], 'Properties::driver', 'Test the Property container accessor for the driver property');


#
# Now test the ODO::Ontology::RDFS::Core convenience methods
#

#
# Perl package names
#

$resource = $VEHICLES->new_instance('ODO::RDFS::Resource', ODO::Node::Resource->new('http://tempuri.org/someResource'));
isa_ok($resource, 'ODO::RDFS::Resource', 'new_instance from Perl package');

$klass = $VEHICLES->new_instance('ODO::RDFS::Class', ODO::Node::Resource->new('http://tempuri.org/someClassDefinition'));
isa_ok($klass, 'ODO::RDFS::Class', 'new_instance from Perl package');

$van = $VEHICLES->new_instance('Van', ODO::Node::Resource->new('http://tempuri.org/myVan'));
isa_ok($van, 'Van', 'new_instance from Perl package');

$driver = $VEHICLES->new_instance('Properties::driver', ODO::Node::Resource->new('http://tempuri.org/firstname/lastname'));
isa_ok($driver, 'Properties::driver', 'new_instance from Perl package');


#
# URI's now
#

#$resource = $VEHICLES->new_instance($ODO::Ontology::RDFS::Vocabulary::Resource->value(), ODO::Node::Resource->new('http://tempuri.org/someResource'));
#isa_ok($resource, 'ODO::RDFS::Resource', 'new_instance from URI');
#
#$klass = $VEHICLES->new_instance($ODO::Ontology::RDFS::Vocabulary::Class->value(), ODO::Node::Resource->new('http://tempuri.org/someClassDefinition'));
#isa_ok($klass, 'ODO::RDFS::Class', 'new_instance from URI');

$van = $VEHICLES->new_instance('http://example.org/schemas/vehicles#Van', ODO::Node::Resource->new('http://tempuri.org/myVan'));
isa_ok($van, 'Van', 'new_instance from URI');

$driver = $VEHICLES->new_instance('http://example.org/schemas/vehicles#driver', ODO::Node::Resource->new('http://tempuri.org/firstname/lastname'));
isa_ok($driver, 'Properties::driver', 'new_instance from URI');


#
# Test the inner workings of new_instance
#

isa_ok($resource->graph(), 'ODO::Graph', 'new_instance correctly set graph');
cmp_ok($resource->graph(), 'eq', $source_data, 'Resource\'s graph is the same as the memory graph');

__END__
