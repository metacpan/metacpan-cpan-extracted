#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/41_parser_ntriples.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 41_parser_ntriples.t,v 1.1 2009-09-22 18:04:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use Test::More qw(no_plan);

use Data::Dumper;

use strict;

sub BEGIN {
	use_ok('ODO::Parser::NTriples');
}

my $BASE_URI = 'http://testuri.org/';
my $NTRIPLE_FILE = 't/data/ntriples.rdf';

my $RDF_DATA;

{
	open(FILE, $NTRIPLE_FILE);
	local $/ = undef;
	$RDF_DATA = <FILE>;
	close(FILE);
}

my $result;

$result = ODO::Parser::NTriples->parse($RDF_DATA, base_uri=> $BASE_URI);
ok($result, 'Parse successful');

cmp_ok(scalar( @{ $result }), '==', 13, 'Make sure we have the right number of triples');


$result = ODO::Parser::NTriples->parse_file($NTRIPLE_FILE, base_uri=> $BASE_URI);
ok($result, 'Parse successful');

cmp_ok(scalar( @{ $result }), '==', 13, 'Make sure we have the right number of triples');


__END__
