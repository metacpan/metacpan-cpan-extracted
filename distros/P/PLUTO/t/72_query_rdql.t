#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/72_query_rdql.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/08/2006
# Revision:	$Id: 72_query_rdql.t,v 1.2 2009-11-23 19:35:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use Test::More qw(no_plan);
use Data::Dumper;

use strict;
use warnings;

require 't/library.pl';

sub BEGIN {
	use_ok('ODO::Query::Simple');
	use_ok('ODO::Query::Simple::Mapper');
	use_ok('ODO::Query::VariablePatternMap');
	use_ok('ODO::Query::RDQL');
	use_ok('ODO::Query::RDQL::Parser');
	use_ok('ODO::Query::RDQL::DefaultHandler');
}

use ODO::Exception;
use ODO::Graph::Simple;
use ODO::Node;
use ODO::Parser::XML;

my $rdql=<<EORDQL;
SELECT 
	?x, ?y
WHERE 
	(<http://never/bag>, abc:q, ?y), (?y, abc:qq, ?dq), (?dq, sdfsdf:sdf, <sfdsfss>), 
	(<http://never/bag>, abc:q, ?y), (?y, abc:qq, ?dq), (?dq, ?dd, ?df), 
	(qbc:aa, dd:adsd, sdfs:dd), 
	(?x, ?h, <sdf>)
AND 
	?x * 2 + 3 > (?y / -3), 
	?y + 2, ?z + 3 == 4, 
	!  ( ?x eq rdf:type && ?y eq rdf:List) 
using 
	abc for < 123 >
EORDQL



# Parse the query in to an object 
my $query = ODO::Query::RDQL::Parser->parse($rdql);
isa_ok($query, 'ODO::Query::RDQL', 'Verify parse result');

cmp_ok(scalar(@{ $query->{'constraints'} }), '==', '4', 'Parse constraint patterns');

# TODO: Add tests that verify the constraints are properly parsed

cmp_ok(scalar(@{ $query->{'statement_patterns'}->{'#patterns'} }), '==', '8', 'Parse statement patterns');
cmp_ok($query->{'prefixes'}->{'abc'}, 'eq', '123', 'Parse prefixes');
cmp_ok(scalar(@{ $query->{'result_vars'}->{'#variables'}}), '==', 2, 'Number of result variables');


my $vpm = ODO::Query::VariablePatternMap->new();
isa_ok($vpm, 'ODO::Query::VariablePatternMap', 'Constructor');


# TODO: Describe the tests that follow


my $PATTERN_CASES = [
	['var:A', 'var:B', 'var:C'] ,
	['var:B', 'var:D', 'var:E'] ,
];


my $PATTERN_RESULTS = {
	'A-B-C'=> [ ['1', '2', '3'], ['4', '5', '6'], ],
	'B-D-E'=> [ ['2', '7', '8'], ['9', '10', '11'] ],
};


# A={1,4}, B={2,5}, C={3,6}
# B={2,9}, D={7,10}, E={8,11}
# The only statements that are consistent:
#
# (A:1, B:2, C:3)
# (B:2, D:7, E:8)
#
# Because B is bound to the value 2 in both statements



# Create the variable pattern map
foreach my $p (@{ $PATTERN_CASES }) {
	my $tm = ODO::Query::Simple->new(make_node($p->[0]), make_node($p->[1]), make_node($p->[2]));

	# Test: __make_pattern_key
	my $key = $vpm->__make_pattern_key($tm);

	# Test: __is_pattern_key
	ok($vpm->__is_pattern_key($key), 'Verify result is a pattern key: ' . $key);
	ok(exists($PATTERN_RESULTS->{ $key }), 'Verify pattern key ' . $key . ' exists in example data');
	
	foreach my $k (@{ $PATTERN_RESULTS->{ $key }} ) {
		my $t = ODO::Statement->new(ODO::Node::Literal->new($k->[0]), ODO::Node::Literal->new($k->[1]), ODO::Node::Literal->new($k->[2]));
		# Test: add
		$vpm->add($tm, $t);
	}
	
	# Test: count_pattern_results
	cmp_ok($vpm->count_pattern_results($tm), '==', '2', 'Count pattern results for key: ' . $key);
}

# Remove the first list from the map
my $p = $PATTERN_CASES->[0];
my $tm = ODO::Query::Simple->new(make_node($p->[0]), make_node($p->[1]), make_node($p->[2]));

# Test: clear_pattern_results, count_pattern_results
$vpm->clear_pattern_results($tm);
cmp_ok($vpm->count_pattern_results($tm), '==', '0', 'Cleared pattern result count for key: ' . $vpm->__make_pattern_key($tm));

my $results = ODO::Graph::Simple->Memory();

foreach my $r (@{ $PATTERN_RESULTS->{ $vpm->__make_pattern_key($tm) } }) {
	my $t = ODO::Statement->new(ODO::Node::Literal->new($r->[0]), ODO::Node::Literal->new($r->[1]), ODO::Node::Literal->new($r->[2]) );
	$results->add($t);
}

# Test: invalidate_results. count_pattern_results
$vpm->invalidate_results($tm, $results);
cmp_ok($vpm->count_pattern_results($tm), '==', '1', 'Invalidated result count');

# Test: known_var_map
cmp_ok($vpm->known_var_map()->{ 'A' }, '==', '1', '"A" is known');
cmp_ok($vpm->known_var_map()->{ 'B' }, '==', '2', '"B" is known');
cmp_ok($vpm->known_var_map()->{ 'C' }, '==', '1', '"C" is known');
cmp_ok($vpm->known_var_map()->{ 'D' }, '==', '1', '"D" is known');
cmp_ok($vpm->known_var_map()->{ 'E' }, '==', '1', '"E" is known');

# Test: known_variable_count
cmp_ok($vpm->known_variable_count($tm), '==', '3', 'Number of known values in triple (A, B, C) ');



$rdql=<<EORDQL;
SELECT
 ?p, ?o
WHERE
	(<http://jastor.adtech.ibm.com/testonts/Ski>, ?p, ?o) 
EORDQL


# Parse the query in to an object 
$query = ODO::Query::RDQL::Parser->parse($rdql);
isa_ok($query, 'ODO::Query::RDQL', 'Verify parse result');


my $data_graph = ODO::Graph::Simple->Memory();
my ($statements, $imports) = ODO::Parser::XML->parse_file('t/data/owllite_example_schema.xml');
$data_graph->add($statements);

# Test: ODO::Query::RDQL::DefaultHandler constructor
my $query_handler = ODO::Query::RDQL::DefaultHandler->new(query_object=> $query, data=> $data_graph);
isa_ok($query_handler, 'ODO::Query::RDQL::DefaultHandler');

my $result_graph = $query_handler->evaluate_query();
isa_ok($result_graph, 'ODO::Graph', 'Verify the result object');
cmp_ok($result_graph->size(), '==', 6, 'Verify the number of statements returned');


__END__
