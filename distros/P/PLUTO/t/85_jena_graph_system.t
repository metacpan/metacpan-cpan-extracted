#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/85_jena_graph_system.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 85_jena_graph_system.t,v 1.5 2009-11-23 18:49:14 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use Test::More skip_all => "Ignored because of problems installing DBD::mysql";
use Data::Dumper;

sub BEGIN {
	use_ok( 'ODO::Jena::Graph::System');
}

# jena.dbcreate --db "jdbc:mysql://localhost:3306/jena" --dbType MySQL --dbUser jena --dbPassword password --model FirstModel

use ODO::DB;
use ODO::Node;
use ODO::Query::Simple;
use ODO::Graph::Simple;

use ODO::Jena::Graph::System;

my ($database, $hostname, $port) = ('jena', 'localhost', '3306');
my ($username, $password) = ('jena', 'password');

my $dbh = ODO::DBI::Connector->connect("DBI:mysql:database=$database;host=$hostname;port=$port", $username, $password) 
  or (print STDERR "To run this test, create a db called 'jena' with user: 'jena' and pass: 'password'\n" and exit);
# exit if we dont have the db created already ...

isa_ok($dbh, 'ODO::DBI::Connector::db');
isa_ok($dbh, 'DBI::db');

my $system_graph = ODO::Jena::Graph::System->new(dbh=> $dbh);
isa_ok($system_graph, 'ODO::Jena::Graph::System');

my $graphs = $system_graph->find_graph('FirstModel');
isa_ok($graphs, 'ARRAY');
cmp_ok(scalar(@{ $graphs }), '==', 1, 'A single graph should exist');

my $first_model = shift @{ $graphs };
isa_ok($first_model, 'ODO::Jena::Graph::Settings');

my $graph_names = $first_model->properties()->GraphName();
cmp_ok(scalar(@{ $graph_names }), '==', 1, 'A single graph name should exist');

my $graph_name = shift @{ $graph_names };
isa_ok($graph_name, 'ODO::Jena::Graph::Properties::GraphName');

my $node = $graph_name->value();
isa_ok($node, 'ODO::Node::Literal'); 
cmp_ok($node->value(), 'eq', 'FirstModel', 'Verify the graph name returned is the proper name');

$dbh->disconnect();

__END__
