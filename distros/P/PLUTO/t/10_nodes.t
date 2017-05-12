#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/10_nodes.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 10_nodes.t,v 1.1 2009-09-22 18:04:54 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use Test::More qw/no_plan/;

use Data::Dumper;

sub BEGIN {
	use_ok( 'ODO::Node' );
}


my $s = ODO::Node::Resource->new('urn:lsid:test.org:ns:object');
my $p = ODO::Node::Resource->new('urn:lsid:test.org:ns:object2');
my $o = ODO::Node::Literal->new('Literal');


isa_ok($s, 'ODO::Node::Resource', 'Resource creation test with LSID');

cmp_ok($s->value(), 'eq', 'urn:lsid:test.org:ns:object', 'Test value function');
cmp_ok($s->uri(), 'eq', 'urn:lsid:test.org:ns:object', 'Test uri function');


isa_ok($p, 'ODO::Node::Resource', 'Resource creation test with typical URI');

cmp_ok($p->value(), 'eq', 'urn:lsid:test.org:ns:object2', 'Test the value function');


isa_ok($o, 'ODO::Node::Literal', 'Literal creation test');

cmp_ok($o->value(), 'eq', 'Literal', 'Test the value function');


my $bnode = ODO::Node::Blank->new('urn:lsid:test.org:ns:object');
cmp_ok($bnode->value(), 'eq', 'urn:lsid:test.org:ns:object', 'Test value function');
cmp_ok($bnode->uri(), 'eq', 'urn:lsid:test.org:ns:object', 'Test uri function');
cmp_ok($bnode->node_id(), 'eq', 'urn:lsid:test.org:ns:object', 'Test node_id function');



# Equality tests

my $is_equal = $s->equal($p);

cmp_ok($is_equal, 'eq', 0, 'Test inequality');

$s = ODO::Node::Resource->new('urn:lsid:test.org:ns:object2');

$is_equal = $s->equal($p);

cmp_ok($is_equal, 'eq', 1, 'Test equality');


# Constructor tests

my $original_s = $s;
$s = ODO::Node::Resource->new($s);

isa_ok($s, 'ODO::Node::Resource', 'New constructed object from existing object');

cmp_ok($s->value(), 'eq', $original_s->value(), 'Test the value');

$is_equal = $s->equal($original_s);

cmp_ok($is_equal, 'eq', 1, 'Test equality');

__END__
