#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/31_graph_memory.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/28/2006
# Revision:	$Id: 31_graph_memory.t,v 1.1 2009-09-22 18:04:52 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use Test::More qw/no_plan/;

use Data::Dumper;

use ODO::Node;
use ODO::Statement;
use ODO::Graph::Simple;

my $s = ODO::Node::Resource->new('http://testuri.org/subject');
my $p = ODO::Node::Resource->new('http://testuri.org/predicate');
my $o = ODO::Node::Resource->new('http://testuri.org/object');

my $stmt = ODO::Statement->new(s=> $s, p=> $p, o=> $o);

my $graph = ODO::Graph::Simple->Memory();
isa_ok($graph, 'ODO::Graph::Simple', 'Created graph object');

$graph->add($stmt);

cmp_ok($graph->size(), 'eq', 1, 'Number of statements == 1');

$graph->add($stmt);

cmp_ok($graph->size(), 'eq', 1, 'Verify duplicate statement is not added');

$graph->clear();

cmp_ok($graph->size(), 'eq', 0, 'Clearing all statements');

1;

__END__
