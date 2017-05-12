#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/43_parser_n3.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/05/2007
# Revision:	$Id: 43_parser_n3.t,v 1.1 2009-09-22 18:04:55 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use Test::More qw(no_plan);

use Data::Dumper;

use strict;

sub BEGIN {
	use_ok('ODO::Parser::N3');
}

my $BASE_URI = 'http://testuri.org/';
my $N3_FILE = 't/data/n3.rdf';

my $RDF_DATA;

{
	open(FILE, $N3_FILE);
	local $/ = undef;
	$RDF_DATA = <FILE>;
	close(FILE);
}

my $result;

$result = ODO::Parser::N3->parse($RDF_DATA, base_uri=> $BASE_URI);
ok($result, 'Parse successful');

cmp_ok(scalar( @{ $result }), '==', 22, 'Make sure we have the right number of triples');


$result = ODO::Parser::N3->parse_file($N3_FILE, base_uri=> $BASE_URI);
ok($result, 'Parse successful');

cmp_ok(scalar( @{ $result }), '==', 22, 'Make sure we have the right number of triples');


__END__
