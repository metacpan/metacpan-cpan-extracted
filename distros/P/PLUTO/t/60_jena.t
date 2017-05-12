#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/60_jena.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 60_jena.t,v 1.1 2009-09-22 18:04:54 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use Test::More qw(no_plan);

use Data::Dumper;

use strict;
use warnings;

sub BEGIN {
	use_ok('ODO::Node');
	use_ok('ODO::Jena');
	use_ok('ODO::Jena::Node');
	use_ok('ODO::Jena::Node::Parser');
}


my $s;
my $p;
my $o;


#
# Sample nodes
# 

$s = ODO::Jena::Node::Parser->parse('Uv::urn:lsid:test.org:ns:object:');
isa_ok($s, 'ODO::Jena::Node::Resource', 'Resource parsing test with LSID');

cmp_ok($s->value(), 'eq', 'urn:lsid:test.org:ns:object', 'Test the parsing of the encoded subject URI');
cmp_ok($s->uri(), 'eq', 'urn:lsid:test.org:ns:object', 'Test alias of the value method');



$p = ODO::Jena::Node::Parser->parse('Uv::http://jena.hpl.hp.com/2003/04/DB#GraphName:');
isa_ok($p, 'ODO::Jena::Node::Resource', 'Resource parsing test with typical URI');

cmp_ok($p->value(), 'eq', 'http://jena.hpl.hp.com/2003/04/DB#GraphName', 'Test the parsing of the encoded predicate URI');



$o = ODO::Jena::Node::Parser->parse('Lv:0::uniprot:');
isa_ok($o, 'ODO::Jena::Node::Literal', 'Literal parsing test');

cmp_ok($o->value(), 'eq', 'uniprot', 'Test the parsing of the encoded object literal');



__END__


my $result;


#
# Test normal Triple
#

my $graphID = '100';

$result = ODO::Graph::Triple->new($s, $p, $o);
isa_ok( $result, 'ODO::Graph::Triple');

cmp_ok($result->graphId(), '==', '100', 'Test the graphId method for Triples');

isa_ok( $result->subject(), 'ODO::Jena::Node::Resource');
isa_ok( $result->predicate(), 'ODO::Jena::Node::Resource');
isa_ok( $result->object(), 'ODO::Jena::Node::Literal');


#
# Test ODO::Graph::Triple::Match
#

$result = ODO::Graph::Triple::Match->new($s, $p, $o, $graphID);
isa_ok( $result, 'ODO::Graph::Triple::Match');

cmp_ok($result->graphId(), '==', '100', 'Test the graphId method for Triple::Match\'es');

isa_ok( $result->subject(), 'ODO::Jena::Node::Resource');
isa_ok( $result->predicate(), 'ODO::Jena::Node::Resource');
isa_ok( $result->object(), 'ODO::Jena::Node::Literal');
