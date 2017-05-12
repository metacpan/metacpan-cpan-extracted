#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/82_ontology_jena.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 82_ontology_jena.t,v 1.4 2009-11-23 20:29:18 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use Test::More qw/no_plan/;
use Data::Dumper;

sub BEGIN {
	use_ok( 'ODO::Jena::Graph::Settings' );
	use_ok( 'ODO::Jena::DB::Settings' );
}

use ODO::Node;
use ODO::Graph::Simple;


my $graph = ODO::Graph::Simple->Memory({name=> 'Graph'});


my $subject = ODO::Node::Resource->new('something');
my $settings = ODO::Jena::Graph::Settings->new($subject, $graph);

isa_ok($settings, 'ODO::Jena::Graph::Settings', 'Graph settings');

my %pset = (
	PSetName=> ODO::Jena::Graph::Properties::PSetName->new(ODO::Node::Literal->new('PSetName')),
	PSetType=> ODO::Jena::Graph::Properties::PSetType->new(ODO::Node::Literal->new('PSetType')),
	PSetTable=> ODO::Jena::Graph::Properties::PSetTable->new(ODO::Node::Literal->new('PSetTable')),
);

isa_ok($pset{PSetName}, 'ODO::Jena::Graph::Properties::PSetName');
isa_ok($pset{PSetType}, 'ODO::Jena::Graph::Properties::PSetType');
isa_ok($pset{PSetTable}, 'ODO::Jena::Graph::Properties::PSetTable');

my $pset = ODO::Jena::Graph::Properties::LSetPSet->new(ODO::Node::Resource->new('http://something/pset/'), $graph, %pset);

isa_ok($pset, 'ODO::Jena::Graph::Properties::LSetPSet');
isa_ok($pset, 'ODO::Jena::Graph::PSet');

my %lset = (
	LSetName=> ODO::Jena::Graph::Properties::LSetName->new(ODO::Node::Literal->new('LSetName')),
	LSetType=> ODO::Jena::Graph::Properties::LSetType->new(ODO::Node::Literal->new('LSetType')),
	LSetPSet=> $pset,
);

isa_ok($lset{LSetName}, 'ODO::Jena::Graph::Properties::LSetName');
isa_ok($lset{LSetType}, 'ODO::Jena::Graph::Properties::LSetType');

my $lset = ODO::Jena::Graph::Properties::GraphLSet->new(ODO::Node::Resource->new('http://something/lset'), $graph, %lset);

isa_ok($lset, 'ODO::Jena::Graph::Properties::GraphLSet');
isa_ok($lset, 'ODO::Jena::Graph::LSet');

my %settings = (
	GraphLSet=> $lset,
	GraphName=> ODO::Jena::Graph::Properties::GraphName->new(ODO::Node::Literal->new('GraphName')),
	GraphType=> ODO::Jena::Graph::Properties::GraphType->new(ODO::Node::Literal->new('GraphType')),
	GraphId=> ODO::Jena::Graph::Properties::GraphId->new(ODO::Node::Literal->new('GraphId')),
);

isa_ok($settings{GraphName}, 'ODO::Jena::Graph::Properties::GraphName');
isa_ok($settings{GraphType}, 'ODO::Jena::Graph::Properties::GraphType');
isa_ok($settings{GraphId}, 'ODO::Jena::Graph::Properties::GraphId');


foreach my $key (keys(%settings)) {
	$settings->properties()->$key($settings{$key});
}

cmp_ok(scalar(@{ $settings->value() }), '==', 10, 'Verify the correct number of statements stored by the object' );

__END__
