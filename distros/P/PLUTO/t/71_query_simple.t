#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/71_query_simple.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/29/2006
# Revision:	$Id: 71_query_simple.t,v 1.1 2009-09-22 18:04:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use Test::More qw(no_plan);
use Data::Dumper;


sub BEGIN {
	use_ok('ODO::Query::Simple');
	use_ok('ODO::Query::Simple::Mapper');
	use_ok('ODO::Query::Simple::Parser');
}

my $s = undef;
my $p = undef ;
my $o = undef;

my $query = ODO::Query::Simple->new(s=> $s, p=> $p, o=> $o);
isa_ok($query, 'ODO::Query::Simple');

isa_ok($query->s(), 'ODO::Node::Any', 'Undefined subject');
isa_ok($query->p(), 'ODO::Node::Any', 'Undefined predicate');
isa_ok($query->o(), 'ODO::Node::Any', 'Undefined object');

$s = ODO::Node::Resource->new('http://testuri.org/subject');

$query =  ODO::Query::Simple->new(s=> $s, p=> $p, o=> $o);

isa_ok($query->s(), 'ODO::Node::Resource', 'Defined subject');
cmp_ok($query->s()->value(), 'eq', 'http://testuri.org/subject', 'Subject is value we set');


# Constructor parameter parsing
$s = ODO::Node::Resource->new('http://testuri.org/subject');


$query =  ODO::Query::Simple->new('s'=> $s);

isa_ok($query, 'ODO::Query::Simple');

isa_ok($query->s(), 'ODO::Node::Resource', 'Defined subject');
cmp_ok($query->s()->value(), 'eq', 'http://testuri.org/subject', 'Subject is value we set');

isa_ok($query->p(), 'ODO::Node::Any', 'Undefined predicate');
isa_ok($query->o(), 'ODO::Node::Any', 'Undefined object');



# Statement pattern parser

my $stmt_pattern = "(<http://testuri.org/subject>, ?p, ?o)";

$query = ODO::Query::Simple::Parser->parse($stmt_pattern);

isa_ok($query, 'ARRAY', 'Result object');
isa_ok($query->[0], 'ODO::Query::Simple', 'First query object');


$query = $query->[0];

isa_ok($query->s(), 'ODO::Node::Resource', 'Defined subject');
cmp_ok($query->s()->value(), 'eq', 'http://testuri.org/subject', 'Subject is value we set');


# Query mapper

__END__
