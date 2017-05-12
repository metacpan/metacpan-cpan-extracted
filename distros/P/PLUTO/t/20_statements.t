#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/20_statements.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 20_statements.t,v 1.1 2009-09-22 18:04:52 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
use Test::More qw/no_plan/;

use Data::Dumper;

sub BEGIN {
	use_ok( 'ODO::Node' );
	use_ok( 'ODO::Statement' );
}

my $s = ODO::Node::Resource->new('urn:lsid:test.org:ns:object');
my $p = ODO::Node::Resource->new('urn:lsid:test.org:ns:object2');
my $o = ODO::Node::Literal->new('Literal');

$result = ODO::Statement->new('s'=> $s, 'p'=> $p, 'o'=> $o);
isa_ok( $result, 'ODO::Statement');

isa_ok( $result->s(), 'ODO::Node::Resource');
isa_ok( $result->p(), 'ODO::Node::Resource');
isa_ok( $result->o(), 'ODO::Node::Literal');

isa_ok( $result->subject(), 'ODO::Node::Resource', 'Test alias of subject method returns an object that');
isa_ok( $result->predicate(), 'ODO::Node::Resource', 'Test alias of predicate method returns an object that');
isa_ok( $result->object(), 'ODO::Node::Literal', 'Test alias of object method returns an object that');

# Test constructors

$result = ODO::Statement->new($s, $p, $o);
isa_ok( $result, 'ODO::Statement', 'Test object returned from constructor parameter mapping');

isa_ok( $result->s(), 'ODO::Node::Resource');
isa_ok( $result->p(), 'ODO::Node::Resource');
isa_ok( $result->o(), 'ODO::Node::Literal');

__END__
